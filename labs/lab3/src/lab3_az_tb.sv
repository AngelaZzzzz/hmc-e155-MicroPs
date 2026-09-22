// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/26/2026
//
// Purpose: Testbench for lab3_az.

`timescale 1 ns/1 ns
 
module lab3_az_tb();
	logic		reset;
	logic [3:0]	col;
	logic [3:0]	row;
	logic [6:0]	seg;
	logic [1:0]	pnp;
 
	localparam	SCAN_MAX	 = 64;
	localparam	DEBOUNCE_MAX = 96;
	localparam	MUX_MAX		 = 48;
	localparam	SETTLE		 = 21 * (SCAN_MAX + 3 * DEBOUNCE_MAX);	// ns: full scan + wait + re-check
 
	lab3_az dut(reset, col, row, seg, pnp);
 
	defparam dut.scanner.MAX_COUNT = SCAN_MAX;
	defparam dut.fsm.DEBOUNCE_MAX  = DEBOUNCE_MAX;
	defparam dut.mux.MAX_COUNT     = MUX_MAX;
 
	// keypad model: one key at (kr, kc); its column is low only while its row is driven
	logic		down;
	logic [1:0]	kr, kc;
	assign col = (down && row[kr]) ? ~(4'b1 << kc) : 4'b1111;
 
	// press or release with contact bounce, starting `offset` ns after a clock edge
	task automatic bounce(input logic final_state, input int offset);
		@(posedge dut.clk); #offset;
		repeat (7) begin
			down = ~down;
			#($urandom_range(50, 200));
		end
		down = final_state;
	endtask
 
	// count key_valid strobes
	int presses;
	always @(posedge dut.clk) if (dut.key_valid) presses++;
 
	// apply stimuli and check outputs
	initial begin
		#2
		reset = 0;										// active-low button pressed
		down = 0; kr = 0; kc = 0; presses = 0;
		#200;
		reset = 1;
		#SETTLE;
 
		// Test 1: display is 00 after reset
		assert ({dut.digit_left, dut.digit_right} == 8'h00)
			$display("PASSED! Display is 00 after reset at time: %0t.", $time);
		else
			$error("FAILED! Display is %h%h instead of 00 after reset at time: %0t.", dut.digit_left, dut.digit_right, $time);
 
		// Test 2: '7' pressed with bounce, mid-clock-cycle: registers once, shows on the right
		kr = 2; kc = 0; bounce(1, 7); #SETTLE;
		assert ({dut.digit_left, dut.digit_right} == 8'h07 && presses == 1)
			$display("PASSED! '7' registered once, display 07, at time: %0t.", $time);
		else
			$error("FAILED! Display %h%h, presses %0d after '7' at time: %0t.", dut.digit_left, dut.digit_right, presses, $time);
 
		// Test 3: holding it a long time does not register again
		#(5 * SETTLE);
		assert (presses == 1)
			$display("PASSED! Long hold still one press at time: %0t.", $time);
		else
			$error("FAILED! Long hold gives %0d presses at time: %0t.", presses, $time);
 
		// Test 4: release with bounce, right on a clock edge: nothing new
		bounce(0, 0); #SETTLE;
		assert ({dut.digit_left, dut.digit_right} == 8'h07 && presses == 1)
			$display("PASSED! Release bounce ignored at time: %0t.", $time);
		else
			$error("FAILED! Display %h%h, presses %0d after release at time: %0t.", dut.digit_left, dut.digit_right, presses, $time);
 
		// Test 5: 'A' pressed right on a clock edge: shifts '7' left
		kr = 0; kc = 3; bounce(1, 0); #SETTLE; bounce(0, 13); #SETTLE;
		assert ({dut.digit_left, dut.digit_right} == 8'h7A && presses == 2)
			$display("PASSED! 'A' shifts display to 7A at time: %0t.", $time);
		else
			$error("FAILED! Display %h%h, presses %0d after 'A' at time: %0t.", dut.digit_left, dut.digit_right, presses, $time);
 
		// Test 6: '0' pressed just before a clock edge (bottom row, so the scanner's last slot)
		kr = 3; kc = 1; bounce(1, 20); #SETTLE; bounce(0, 3); #SETTLE;
		assert ({dut.digit_left, dut.digit_right} == 8'hA0 && presses == 3)
			$display("PASSED! '0' shifts display to A0 at time: %0t.", $time);
		else
			$error("FAILED! Display %h%h, presses %0d after '0' at time: %0t.", dut.digit_left, dut.digit_right, presses, $time);
 
		// Test 7: the left display (pnp[1]) shows 'A' when its anode is on
		@(posedge pnp[1]); #1;
		assert (seg == 7'b0001000)
			$display("PASSED! Left display shows A (seg %b) at time: %0t.", seg, $time);
		else
			$error("FAILED! Left display seg %b instead of 0001000 for A at time: %0t.", seg, $time);
 
		// Test 8: the right display (pnp[0]) shows '0' when its anode is on
		@(posedge pnp[0]); #1;
		assert (seg == 7'b1000000)
			$display("PASSED! Right display shows 0 (seg %b) at time: %0t.", seg, $time);
		else
			$error("FAILED! Right display seg %b instead of 1000000 for 0 at time: %0t.", seg, $time);
 
		#100 $stop;
	end
 
endmodule
