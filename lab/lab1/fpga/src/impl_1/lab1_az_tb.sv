`timescale 1 ns/1 ns

module lab1_az_tb();

	logic [3:0]		s;
	logic			reset;
	logic [2:0]		led;
	logic [6:0]		seg;
	logic			clk;
	
	lab1_az dut(s, reset, led, seg, clk);
 
	// apply stimuli and check outputs
	initial begin
 
		reset = 1;
		s     = 4'b0000;
		#100 reset = 0;
 
		// TEST 1: switch-to-LED assign logic for led0 and led1
 
		// Test 1
		s = 4'b0000;
		#10;
		assert (led[1:0] == 2'b00)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 2
		s = 4'b0001;
		#10;
		assert (led[1:0] == 2'b01)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 3
		s = 4'b0010;
		#10;
		assert (led[1:0] == 2'b01)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 4
		s = 4'b0011;
		#10;
		assert (led[1:0] == 2'b00)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 5
		s = 4'b0100;
		#10;
		assert (led[1:0] == 2'b00)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 6
		s = 4'b0101;
		#10;
		assert (led[1:0] == 2'b01)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 7
		s = 4'b0110;
		#10;
		assert (led[1:0] == 2'b01)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 8
		s = 4'b0111;
		#10;
		assert (led[1:0] == 2'b00)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 9
		s = 4'b1000;
		#10;
		assert (led[1:0] == 2'b00)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 10
		s = 4'b1001;
		#10;
		assert (led[1:0] == 2'b01)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 11
		s = 4'b1010;
		#10;
		assert (led[1:0] == 2'b01)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 12
		s = 4'b1011;
		#10;
		assert (led[1:0] == 2'b00)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 13
		s = 4'b1100;
		#10;
		assert (led[1:0] == 2'b10)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 14
		s = 4'b1101;
		#10;
		assert (led[1:0] == 2'b11)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 15
		s = 4'b1110;
		#10;
		assert (led[1:0] == 2'b11)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// Test 16
		s = 4'b1111;
		#10;
		assert (led[1:0] == 2'b10)
			$display("PASSED! The led controller behaves as desired at time: %0t.", $time);
		else
			$error("FAILED! The led controller behaves incorrectly at time: %0t.", $time);
 
		// TEST 2: the 7 segment decoder is wired correctly
		s = 4'h0;
		#10;
		assert (seg == 7'b1000000)
			$display("PASSED! The decoder is wired correctly at time: %0t.", $time);
		else
			$error("FAILED! The decoder is miswired at time: %0t.", $time);
 
		s = 4'hF;
		#10;
		assert (seg == 7'b0001110)
			$display("PASSED! The decoder is wired correctly at time: %0t.", $time);
		else
			$error("FAILED! The decoder is miswired at time: %0t.", $time);
 
		// TEST 3: the LED controller is wired to led[2] and is driving it correctly
		reset = 1;
		assert (led[2] == 1'b1)
			$display("PASSED! led[2] is driven by the blinker at time: %0t.", $time);
		else
			$error("FAILED! led[2] is not driven at time: %0t.", $time);
 
		#100 $stop;
	
	end

endmodule