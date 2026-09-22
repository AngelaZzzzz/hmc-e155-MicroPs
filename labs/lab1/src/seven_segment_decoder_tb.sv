`timescale 1 ns/1 ns

module seven_segment_decoder_tb();
	logic			clk;
	logic [3:0]	s;
	logic	[6:0]	seg;
	
	seven_segment_decoder dut(s, seg);
	
	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	// We change s at rising edge and check output at falling edge of clk
	initial begin
	
		// Test 0
		@(posedge clk);
		s = 4'h0;
		@(negedge clk);
		assert (seg == 7'b1000000)
			$display("PASSED! Digit 0 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 0 displays incorrectly at time: %0t.", $time);
 
		// Test 1
		@(posedge clk);
		s = 4'h1;
		@(negedge clk);
		assert (seg == 7'b1111001)
			$display("PASSED! Digit 1 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 1 displays incorrectly at time: %0t.", $time);
 
		// Test 2
		@(posedge clk);
		s = 4'h2;
		@(negedge clk);
		assert (seg == 7'b0100100)
			$display("PASSED! Digit 2 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 2 displays incorrectly at time: %0t.", $time);
 
		// Test 3
		@(posedge clk);
		s = 4'h3;
		@(negedge clk);
		assert (seg == 7'b0110000)
			$display("PASSED! Digit 3 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 3 displays incorrectly at time: %0t.", $time);
 
		// Test 4
		@(posedge clk);
		s = 4'h4;
		@(negedge clk);
		assert (seg == 7'b0011001)
			$display("PASSED! Digit 4 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 4 displays incorrectly at time: %0t.", $time);
 
		// Test 5
		@(posedge clk);
		s = 4'h5;
		@(negedge clk);
		assert (seg == 7'b0010010)
			$display("PASSED! Digit 5 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 5 displays incorrectly at time: %0t.", $time);
 
		// Test 6
		@(posedge clk);
		s = 4'h6;
		@(negedge clk);
		assert (seg == 7'b0000010)
			$display("PASSED! Digit 6 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 6 displays incorrectly at time: %0t.", $time);
 
		// Test 7
		@(posedge clk);
		s = 4'h7;
		@(negedge clk);
		assert (seg == 7'b1111000)
			$display("PASSED! Digit 7 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 7 displays incorrectly at time: %0t.", $time);
 
		// Test 8
		@(posedge clk);
		s = 4'h8;
		@(negedge clk);
		assert (seg == 7'b0000000)
			$display("PASSED! Digit 8 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 8 displays incorrectly at time: %0t.", $time);
 
		// Test 9
		@(posedge clk);
		s = 4'h9;
		@(negedge clk);
		assert (seg == 7'b0010000)
			$display("PASSED! Digit 9 displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit 9 displays incorrectly at time: %0t.", $time);
 
		// Test A
		@(posedge clk);
		s = 4'hA;
		@(negedge clk);
		assert (seg == 7'b0001000)
			$display("PASSED! Digit A displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit A displays incorrectly at time: %0t.", $time);
 
		// Test b
		@(posedge clk);
		s = 4'hB;
		@(negedge clk);
		assert (seg == 7'b0000011)
			$display("PASSED! Digit b displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit b displays incorrectly at time: %0t.", $time);
 
		// Test C
		@(posedge clk);
		s = 4'hC;
		@(negedge clk);
		assert (seg == 7'b1000110)
			$display("PASSED! Digit C displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit C displays incorrectly at time: %0t.", $time);
 
		// Test d
		@(posedge clk);
		s = 4'hD;
		@(negedge clk);
		assert (seg == 7'b0100001)
			$display("PASSED! Digit d displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit d displays incorrectly at time: %0t.", $time);
 
		// Test E
		@(posedge clk);
		s = 4'hE;
		@(negedge clk);
		assert (seg == 7'b0000110)
			$display("PASSED! Digit E displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit E displays incorrectly at time: %0t.", $time);
 
		// Test F
		@(posedge clk);
		s = 4'hF;
		@(negedge clk);
		assert (seg == 7'b0001110)
			$display("PASSED! Digit F displays correctly at time: %0t.", $time);
		else
			$error("FAILED! Digit F displays incorrectly at time: %0t.", $time);
 
		#100 $stop;
	
	end

endmodule