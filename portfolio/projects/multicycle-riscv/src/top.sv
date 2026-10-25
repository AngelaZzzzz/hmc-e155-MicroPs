module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

	logic [31:0] PC, ReadData;
  
  // instantiate processor and memories
  RISCVmulticycle RISCVmulticycle(clk, reset, PC, MemWrite, DataAdr, WriteData, ReadData);
  mem mem(clk, MemWrite, DataAdr, WriteData, ReadData);

endmodule


module mem(input  logic        clk, WE,
           input  logic [31:0] A, WD,
           output logic [31:0] RD);

  logic [31:0] RAM[63:0];
  
  initial $readmemh("memfile.dat", RAM);

  assign RD = RAM[A[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (WE) RAM[A[31:2]] <= WD;
endmodule


module RISCVmulticycle(input  logic        clk, reset,
                       output logic [31:0] PC,
                       output logic        MemWrite,
                       output logic [31:0] DataAdr, WriteData,
                       input  logic [31:0] ReadData);

  logic       RegWrite, PCUpdate, Zero, AdrSrc, IRWrite, PCWrite;
  logic [1:0] ALUSrcA, ALUSrcB, ResultSrc, ImmSrc;
  logic [2:0] ALUControl;
  logic [31:0] ALUResult;
  logic [31:0] Instr;

  controller c(clk, reset, Instr[6:0], Instr[14:12], Instr[30], Zero,
               ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl,
               IRWrite, PCWrite, RegWrite, MemWrite, PCUpdate);

	datapath dp(clk, reset, ResultSrc, ALUSrcA, ALUSrcB, RegWrite,
					ImmSrc, ALUControl, IRWrite, PCWrite, AdrSrc, Zero, PC,
					ALUResult, WriteData, ReadData, DataAdr, Instr);
endmodule


module controller(input  logic       clk,
                  input  logic       reset,  
                  input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrca, ALUSrcb,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite, PCUpdate);

	logic [1:0] ALUOp;
	logic       Branch;

	maindec md(clk, reset, op, ResultSrc, MemWrite, Branch, ALUSrca, ALUSrcb, RegWrite, ImmSrc, ALUOp, AdrSrc, IRWrite, PCUpdate);
	aludec  ad(op[5], funct3, funct7b5, ALUOp, ALUControl);

	assign PCWrite = (Branch & Zero) | PCUpdate;

endmodule


module datapath(input  logic        clk, reset,
                input  logic [1:0]  ResultSrc, 
                input  logic [1:0]  ALUSrcA, ALUSrcB,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic [2:0]  ALUControl,
                input  logic        IRWrite, PCWrite,
                input  logic        AdrSrc,
                output logic        Zero,
                output logic [31:0] PC,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData,
                output logic [31:0] DataAdr,
                output logic [31:0] Instr);

  logic [31:0] OldPC;
  logic [31:0] ImmExt;
  logic [31:0] SrcA, SrcB;
  logic [31:0] A, RD1, RD2;
  logic [31:0] Result, ALUOut, Data;
 
  // next PC logic & stages logic
  flopenr #(32) pcreg(clk, reset, PCWrite, Result, PC);
  mux2 #(32)  pcmux(PC, Result, AdrSrc, DataAdr);
  flopenr #(32) oldpcreg(clk, reset, IRWrite, PC, OldPC);
  flopenr #(32) instreg(clk, reset, IRWrite, ReadData, Instr);
  flopr #(32) datareg(clk, reset, ReadData, Data);
  flopr #(32) rd1reg(clk, reset, RD1, A);
  flopr #(32) rd2reg(clk, reset, RD2, WriteData);
  flopr #(32) alureg(clk, reset, ALUResult, ALUOut);
 
  // register file logic
  RegFile     RF(clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], 
                 Result, RD1, RD2);
  Extend      EXT(Instr[31:7], ImmSrc, ImmExt);

  // ALU logic
  mux3 #(32)  srcamux(PC, OldPC, A, ALUSrcA, SrcA);
  mux3 #(32)  srcbmux(WriteData, ImmExt, 32'd4, ALUSrcB, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, ALUResult, Zero);
  mux3 #(32)  resultmux(ALUOut, Data, ALUResult, ResultSrc, Result);
endmodule


module aludec(input  logic       opb5,
              input  logic [2:0] funct3,
              input  logic       funct7b5, 
              input  logic [1:0] ALUOp,
              output logic [2:0] ALUControl);

  logic  RtypeSub;
  assign RtypeSub = funct7b5 & opb5;  // TRUE for R-type subtract instruction

  always_comb
    case(ALUOp)
      2'b00:                ALUControl = 3'b000; // addition
      2'b01: 					 ALUControl = 3'b001; // subtraction
      default: case(funct3) // R-type or I-type ALU
                 3'b000:  if (RtypeSub) 
                            ALUControl = 3'b001; // sub
                          else          
                            ALUControl = 3'b000; // add, addi
                 3'b010:    ALUControl = 3'b101; // slt, slti
                 3'b110:    ALUControl = 3'b011; // or, ori
                 3'b111:    ALUControl = 3'b010; // and, andi
                 default:   ALUControl = 3'b000; // ???
               endcase
    endcase
endmodule


module alu(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  logic [31:0] condinvb, sum;

  assign condinvb = alucontrol[0] ? ~b : b;
  assign sum = a + condinvb + alucontrol[0];

  always_comb
    case (alucontrol)
      3'b000:  result = sum;       // add
      3'b001:  result = sum;       // subtract
      3'b010:  result = a & b;     // and
      3'b011:  result = a | b;     // or
      3'b101:  result = sum[31];   // slt
      default: result = 32'b0;
    endcase

  assign zero = (result == 32'b0);
endmodule 


module Extend(input  logic [31:7] Instr,
              input  logic [1:0]  ImmSrc,
              output logic [31:0] ImmExt);
 
  always_comb
    case(ImmSrc) 
               // I-type 
      2'b00:   ImmExt = {{20{Instr[31]}}, Instr[31:20]};  
               // S-type (Stores)
      2'b01:   ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]}; 
               // B-type (Branches)
      2'b10:   ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0}; 
               // J-type (Jumps)
      2'b11:   ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0}; 
      default: ImmExt = 32'b0;
    endcase             
endmodule


module RegFile(input  logic        clk, 
               input  logic        WE3, 
               input  logic [ 4:0] A1, A2, A3, 
               input  logic [31:0] WD3, 
               output logic [31:0] RD1, RD2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (WE3) rf[A3] <= WD3;	

  assign RD1 = (A1 != 0) ? rf[A1] : 0;
  assign RD2 = (A2 != 0) ? rf[A2] : 0;
endmodule


module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule


module flopenr #(parameter WIDTH = 8)
                (input  logic             clk, reset, en,
                 input  logic [WIDTH-1:0] d,
                 output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset)    q <= 0;
    else if (en)  q <= d;
endmodule


module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule


module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule
