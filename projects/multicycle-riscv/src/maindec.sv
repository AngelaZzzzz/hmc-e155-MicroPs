module maindec(input  logic       clk,
               input  logic       reset, 
					input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch,
					output logic [1:0] ALUSrca, ALUSrcb,
               output logic       RegWrite,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp,
					output logic 		 AdrSrc,
					output logic 		 IRWrite, PCUpdate);

	typedef enum logic [3:0] {S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10} statetype;
	statetype state, nextstate;
  
	always_ff @(posedge clk, posedge reset)
			if (reset) state <= S0;
			else		  state <= nextstate;
	
	// next-state logic
	always_comb
		case(state)
			S0: 	nextstate = S1;
			S1:	case(op)
						7'b0000011: nextstate = S2; // lw
						7'b0100011: nextstate = S2; // sw
						7'b0110011: nextstate = S6; // R-type 
						7'b1100011: nextstate = S10;// beq
						7'b0010011: nextstate = S8; // I-type
						7'b1101111: nextstate = S9; // jal
						default:    nextstate = S0;
					endcase
				
			S2: 	case(op)
						7'b0000011: nextstate = S3; // lw
						7'b0100011: nextstate = S5; // sw
						default:    nextstate = S0;
					endcase
	
			S3:	nextstate = S4;
			S4: 	nextstate = S0;
			S5: 	nextstate = S0;
			S6: 	nextstate = S7;
			S7:	nextstate = S0;
			S8:	nextstate = S7;
			S9:	nextstate = S7;
			S10:	nextstate = S0;

			default: nextstate = S0;
		endcase


	// output logic
	always_comb begin
		// default values
		RegWrite  = 1'b0;
		ImmSrc    = 2'b00;
		ALUSrca   = 2'b00;
		ALUSrcb   = 2'b00;
		MemWrite  = 1'b0;
		ResultSrc = 2'b00;
		Branch    = 1'b0;
		ALUOp     = 2'b00;
		AdrSrc    = 1'b0;
		IRWrite   = 1'b0;
		PCUpdate  = 1'b0;
	
		case(op)
			7'b0100011:    ImmSrc = 2'b01; // sw
			7'b1100011:    ImmSrc = 2'b10; // beq
			7'b1101111:    ImmSrc = 2'b11; // jal
			default:   		ImmSrc = 2'b00;
		endcase
	
		case(state)
			S0: begin
			  AdrSrc    = 1'b0;
			  IRWrite   = 1'b1;
			  ALUSrca   = 2'b00;
			  ALUSrcb   = 2'b10;
			  ALUOp     = 2'b00;
			  ResultSrc = 2'b10;
			  PCUpdate  = 1'b1;
			end
	
			S1: begin
			  ALUSrca = 2'b01;
			  ALUSrcb = 2'b01;
			  ALUOp   = 2'b00;
			end
	
			S2: begin
			  ALUSrca = 2'b10;
			  ALUSrcb = 2'b01;
			  ALUOp   = 2'b00;
			end
	
			S3: begin
			  ResultSrc = 2'b00;
			  AdrSrc    = 1'b1;
			end
	
			S4: begin
			  ResultSrc = 2'b01;
			  RegWrite  = 1'b1;
			end
	
			S5: begin
			  ResultSrc = 2'b00;
			  AdrSrc    = 1'b1;
			  MemWrite  = 1'b1;
			end
	
			S6: begin
			  ALUSrca = 2'b10;
			  ALUSrcb = 2'b00;
			  ALUOp   = 2'b10;
			end
			
			S7: begin
			  ResultSrc = 2'b00;
			  RegWrite  = 1'b1;
			end
	
			S8: begin
			  ALUSrca = 2'b10;
			  ALUSrcb = 2'b01;
			  ALUOp   = 2'b10;
			end
	
			S9: begin
			  ALUSrca   = 2'b01;
			  ALUSrcb   = 2'b10;
			  ALUOp     = 2'b00;
			  ResultSrc = 2'b00;
			  PCUpdate  = 1'b1;
			end
	
			S10: begin
			  ALUSrca   = 2'b10;
			  ALUSrcb   = 2'b00;
			  ALUOp     = 2'b01;
			  ResultSrc = 2'b00;
			  Branch    = 1'b1;
			 end
		endcase
	end

endmodule
