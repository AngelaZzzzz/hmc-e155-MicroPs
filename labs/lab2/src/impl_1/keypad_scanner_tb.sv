`timescale 1 ns/1 ns
 
module keypad_scanner_tb();
	logic		clk;
	logic		reset;
	logic		enable;
	logic [3:0]	row;
	
	localparam	WIDTH		= 4;
	localparam	MAX_COUNT	= 12;
	localparam	STEP		= MAX_COUNT / 4;
	
	keypad_scanner #(WIDTH, MAX_COUNT) dut(clk, reset, enable, row);
	
	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	// apply stimuli and check outputs
	initial begin
		#2
		reset  = 1;
		enable = 1;
	
		// Test 1: reset the scanner, expected first row asserted
		#1;
		assert (row == 4'b1000)
			$display("PASSED! Scanner starts at 1000 after reset at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 1000 after reset at time: %0t.", row, $time);
			
		// Test 2: the state counter is not enabled until the prescaler wraps, so the output holds while the counter counts
		reset = 0;
		repeat (STEP - 1) @(posedge clk); #1;
		assert (row == 4'b1000)
			$display("PASSED! Output holds at 1000 while the state counter is disabled at time: %0t.", $time);
		else
			$error("FAILED! Output changed to %b before the state counter was enabled at time: %0t.", row, $time);
			
		// Test 3: first transition, 1000 -> 0100
		@(posedge clk); #1;
		assert (row == 4'b0100)
			$display("PASSED! Scanner transitions 1000 -> 0100 at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0100 at time: %0t.", row, $time);
			
		// Test 4: the output holds for a full row period
		repeat (STEP - 1) @(posedge clk); #1;
		assert (row == 4'b0100)
			$display("PASSED! Output holds at 0100 for a full row period at time: %0t.", $time);
		else
			$error("FAILED! Output changed to %b early at time: %0t.", row, $time);
			
		// Test 5: second transition, 0100 -> 0010
		@(posedge clk); #1;
		assert (row == 4'b0010)
			$display("PASSED! Scanner transitions 0100 -> 0010 at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0010 at time: %0t.", row, $time);
			
		// Test 6: third transition, 0010 -> 0001
		repeat (STEP) @(posedge clk); #1;
		assert (row == 4'b0001)
			$display("PASSED! Scanner transitions 0010 -> 0001 at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0001 at time: %0t.", row, $time);
			
		// Test 7: fourth transition, 0001 -> 1000 (the scan wraps)
		repeat (STEP) @(posedge clk); #1;
		assert (row == 4'b1000)
			$display("PASSED! Scanner wraps 0001 -> 1000 at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 1000 after wrapping at time: %0t.", row, $time);
			
		// Test 8: the scan is running again on the second pass
		repeat (STEP) @(posedge clk); #1;
		assert (row == 4'b0100)
			$display("PASSED! Scanner steps to 0100 on the second pass at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0100 on the second pass at time: %0t.", row, $time);
			
		// Test 9: the scanner holds its output while enable is low
		enable = 0;
		repeat (2 * STEP) @(posedge clk); #1;
		assert (row == 4'b0100)
			$display("PASSED! Scanner holds at 0100 while disabled at time: %0t.", $time);
		else
			$error("FAILED! Scanner moved to %b while disabled at time: %0t.", row, $time);
			
		// Test 10: the scanner picks up where it left off when enable returns
		enable = 1;
		repeat (STEP - 1) @(posedge clk); #1;
		assert (row == 4'b0100)
			$display("PASSED! Scanner resumes the rest of the 0100 step at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0100 after re-enabling at time: %0t.", row, $time);
			
		// Test 11: and then keeps stepping normally
		@(posedge clk); #1;
		assert (row == 4'b0010)
			$display("PASSED! Scanner steps to 0010 after re-enabling at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0010 after re-enabling at time: %0t.", row, $time);
			
		// Test 12: reset in the middle of a scan returns to 1000
		reset = 1;
		#1;
		assert (row == 4'b1000)
			$display("PASSED! Reset mid-scan returns to 1000 at time: %0t.", $time);
		else
			$error("FAILED! Reset mid-scan gives %b at time: %0t.", row, $time);
			
		// Test 13: the scanner resumes stepping after reset is released
		reset = 0;
		repeat (STEP) @(posedge clk); #1;
		assert (row == 4'b0100)
			$display("PASSED! Scanner resumes stepping after reset at time: %0t.", $time);
		else
			$error("FAILED! Scanner is %b instead of 0100 after reset released at time: %0t.", row, $time);
			
		#100 $stop;
	
	end
 
endmodule
 