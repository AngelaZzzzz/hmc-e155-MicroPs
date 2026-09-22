// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/26/2026
//
// Purpose: Testbench for digit_register. Checks reset to 00, that a key_valid strobe
//			shifts the old right digit to the left and puts the new key on the right,
//			and that the digits hold when key_valid is low.

`timescale 1 ns/1 ns

module digit_register_tb();
	logic		clk;
	logic		reset;
	logic		key_valid;
	logic [3:0]	key;
	logic [3:0]	digit_left;
	logic [3:0]	digit_right;

	digit_register dut(clk, reset, key_valid, key, digit_left, digit_right);

	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end

	// apply stimuli and check outputs
	initial begin
		#2
		reset     = 1;
		key_valid = 0;
		key       = 4'h0;

		// Test 1: reset clears both digits
		#1;
		assert ({digit_left, digit_right} == 8'h00)
			$display("PASSED! Digits are 00 after reset at time: %0t.", $time);
		else
			$error("FAILED! Digits are %h%h instead of 00 after reset at time: %0t.", digit_left, digit_right, $time);

		reset = 0;

		// Test 2: first key lands on the right
		key = 4'h7; key_valid = 1;
		@(posedge clk); #1;
		key_valid = 0;
		assert ({digit_left, digit_right} == 8'h07)
			$display("PASSED! First key gives 07 at time: %0t.", $time);
		else
			$error("FAILED! First key gives %h%h instead of 07 at time: %0t.", digit_left, digit_right, $time);

		// Test 3: second key shifts the first one left
		key = 4'hA; key_valid = 1;
		@(posedge clk); #1;
		key_valid = 0;
		assert ({digit_left, digit_right} == 8'h7A)
			$display("PASSED! Second key gives 7A at time: %0t.", $time);
		else
			$error("FAILED! Second key gives %h%h instead of 7A at time: %0t.", digit_left, digit_right, $time);

		// Test 4: third key pushes the first one out
		key = 4'h3; key_valid = 1;
		@(posedge clk); #1;
		key_valid = 0;
		assert ({digit_left, digit_right} == 8'hA3)
			$display("PASSED! Third key gives A3 at time: %0t.", $time);
		else
			$error("FAILED! Third key gives %h%h instead of A3 at time: %0t.", digit_left, digit_right, $time);

		// Test 5: key changes without key_valid are ignored
		key = 4'hF;
		repeat (3) @(posedge clk); #1;
		assert ({digit_left, digit_right} == 8'hA3)
			$display("PASSED! Digits hold at A3 without key_valid at time: %0t.", $time);
		else
			$error("FAILED! Digits changed to %h%h without key_valid at time: %0t.", digit_left, digit_right, $time);

		// Test 6: key_valid held for several clocks shifts every clock (the FSM only ever gives one)
		key_valid = 1;
		repeat (2) @(posedge clk); #1;
		key_valid = 0;
		assert ({digit_left, digit_right} == 8'hFF)
			$display("PASSED! Two-clock key_valid shifts twice to FF at time: %0t.", $time);
		else
			$error("FAILED! Two-clock key_valid gives %h%h instead of FF at time: %0t.", digit_left, digit_right, $time);

		// Test 7: reset in the middle clears again
		reset = 1; #1;
		assert ({digit_left, digit_right} == 8'h00)
			$display("PASSED! Mid-run reset clears to 00 at time: %0t.", $time);
		else
			$error("FAILED! Mid-run reset gives %h%h instead of 00 at time: %0t.", digit_left, digit_right, $time);
		reset = 0;

		#100 $stop;
	end

endmodule
