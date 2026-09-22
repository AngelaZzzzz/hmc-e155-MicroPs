// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: Testbench for keypad_fsm. Drives the synchronized (active-low) column input
//			directly with the debounce wait shrunk to DEBOUNCE_MAX = 2 clocks.

`timescale 1 ns/1 ns
 
module keypad_fsm_tb();
	logic		clk;
	logic		reset;
	logic [3:0]	col_sync;
	logic		scan_enable;
	logic		key_valid;
	int			presses;
 
	localparam	WIDTH		 = 3;
	localparam	DEBOUNCE_MAX = 4;
 
	keypad_fsm #(WIDTH, DEBOUNCE_MAX) dut(clk, reset, col_sync, scan_enable, key_valid);
 
	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end
 
	// count key_valid pulses
	always @(posedge clk) if (key_valid) presses++;
 
	// apply stimuli and check outputs
	initial begin
		#2
		reset    = 1;
		col_sync = 4'b1111;
		presses  = 0;
 
		// Test 1: scanning after reset
		#1;
		assert (scan_enable == 1)
			$display("PASSED! Scanning after reset at time: %0t.", $time);
		else
			$error("FAILED! Not scanning after reset at time: %0t.", $time);
 
		reset = 0;
 
		// Test 2: a key freezes the scanner within a clock of being seen
		col_sync = 4'b1101;
		@(posedge clk); #1;
		assert (scan_enable == 0)
			$display("PASSED! Scanner frozen when a key is seen at time: %0t.", $time);
		else
			$error("FAILED! Scanner still running with a key down at time: %0t.", $time);
 
		// Test 3: a key that disappears before the debounce wait ends is not registered
		@(posedge clk);
		col_sync = 4'b1111;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 0)
			$display("PASSED! Glitch shorter than the debounce wait not registered at time: %0t.", $time);
		else
			$error("FAILED! Glitch registered %0d press(es) at time: %0t.", presses, $time);
 
		// Test 4: and scanning resumes afterwards
		assert (scan_enable == 1)
			$display("PASSED! Scanning resumed after the glitch at time: %0t.", $time);
		else
			$error("FAILED! Scanner did not resume after the glitch at time: %0t.", $time);
 
		// Test 5: a steady key registers exactly once
		col_sync = 4'b1101;
		repeat (2 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 1)
			$display("PASSED! Steady key registered once at time: %0t.", $time);
		else
			$error("FAILED! Steady key registered %0d time(s) at time: %0t.", presses, $time);
 
		// Test 6: holding it much longer does not register again
		repeat (5 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 1)
			$display("PASSED! Long hold still registered once at time: %0t.", $time);
		else
			$error("FAILED! Long hold registered %0d time(s) at time: %0t.", presses, $time);
 
		// Test 7: the scanner stays frozen while the key is held
		assert (scan_enable == 0)
			$display("PASSED! Scanner frozen while the key is held at time: %0t.", $time);
		else
			$error("FAILED! Scanner running while the key is held at time: %0t.", $time);
 
		// Test 8: a contact glitch while holding (shorter than the release wait) does not re-register
		col_sync = 4'b1111;
		repeat (2) @(posedge clk);
		col_sync = 4'b1101;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 1)
			$display("PASSED! Glitch while holding ignored at time: %0t.", $time);
		else
			$error("FAILED! Glitch while holding registered, presses = %0d at time: %0t.", presses, $time);
 
		// Test 9: release with bounce does not re-register
		col_sync = 4'b1111;
		repeat (2) @(posedge clk);
		col_sync = 4'b1101;
		repeat (2) @(posedge clk);
		col_sync = 4'b1111;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 1)
			$display("PASSED! Release bounce ignored at time: %0t.", $time);
		else
			$error("FAILED! Release bounce registered, presses = %0d at time: %0t.", presses, $time);
 
		// Test 10: scanning resumes after release
		assert (scan_enable == 1)
			$display("PASSED! Scanning resumed after release at time: %0t.", $time);
		else
			$error("FAILED! Scanner did not resume after release at time: %0t.", $time);
 
		// Test 11: two keys at once register nothing
		col_sync = 4'b1100;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 1)
			$display("PASSED! Two keys at once not registered at time: %0t.", $time);
		else
			$error("FAILED! Two keys at once registered, presses = %0d at time: %0t.", presses, $time);
 
		// Test 12: and the scanner stays frozen while they are held
		assert (scan_enable == 0)
			$display("PASSED! Scanner frozen during a multi-key hold at time: %0t.", $time);
		else
			$error("FAILED! Scanner running during a multi-key hold at time: %0t.", $time);
 
		// Test 13: releasing one of the two registers the survivor once
		col_sync = 4'b1101;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 2)
			$display("PASSED! Survivor of a two-key hold registered once at time: %0t.", $time);
		else
			$error("FAILED! Survivor gives presses = %0d instead of 2 at time: %0t.", presses, $time);
 
		// Test 14: a second key joining a registered key registers nothing
		col_sync = 4'b1001;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 2)
			$display("PASSED! Key added during a hold not registered at time: %0t.", $time);
		else
			$error("FAILED! Key added during a hold registered, presses = %0d at time: %0t.", presses, $time);
 
		// Test 15: bounce while releasing the first key (survivor not yet steady) registers nothing
		col_sync = 4'b1011; @(posedge clk);
		col_sync = 4'b1001; @(posedge clk);
		col_sync = 4'b1011; @(posedge clk);
		col_sync = 4'b1001; repeat (2 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 2)
			$display("PASSED! Bounce during a partial release not registered at time: %0t.", $time);
		else
			$error("FAILED! Bounce during a partial release registered, presses = %0d at time: %0t.", presses, $time);
 
		// Test 16: once the first key is steadily gone, the remaining key registers
		col_sync = 4'b1011;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 3)
			$display("PASSED! Remaining key registered after the first was released at time: %0t.", $time);
		else
			$error("FAILED! Remaining key gives presses = %0d instead of 3 at time: %0t.", presses, $time);
 
		// Test 17: releasing everything from a multi-key hold registers nothing and scanning resumes
		col_sync = 4'b1000;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk);
		col_sync = 4'b1111;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 3 && scan_enable == 1)
			$display("PASSED! Full release from multi-key hold: nothing registered, scanning at time: %0t.", $time);
		else
			$error("FAILED! Full release gives presses = %0d, scan_enable = %b at time: %0t.", presses, scan_enable, $time);
 
		// Test 18: a normal press afterwards still registers
		col_sync = 4'b0111;
		repeat (3 * DEBOUNCE_MAX) @(posedge clk); #1;
		assert (presses == 4)
			$display("PASSED! Normal press after multi-key handling registered at time: %0t.", $time);
		else
			$error("FAILED! Normal press gives presses = %0d instead of 4 at time: %0t.", presses, $time);
 
		// Test 19: reset mid-hold returns to scanning
		reset = 1; #1;
		assert (scan_enable == 1)
			$display("PASSED! Reset returns to scanning at time: %0t.", $time);
		else
			$error("FAILED! Not scanning after mid-hold reset at time: %0t.", $time);
		reset = 0;
 
		#100 $stop;
	end
 
endmodule
