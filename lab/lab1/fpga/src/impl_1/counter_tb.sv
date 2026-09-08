`timescale 1 ns/1 ns

module counter_tb();
	
	localparam	WIDTH		= 4;
	localparam	MAX_COUNT	= 10;
	
	logic				clk;
	logic 				reset;
	logic				enable;
	logic [WIDTH-1:0]	count;
	
	counter #(WIDTH, MAX_COUNT) dut(clk, reset, enable, count);
	
	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	// apply stimuli and check outputs
	initial begin
		reset = 1;
	
		// Test 1: reset the counter, count should be zero
		enable = 1;
		@(posedge clk); #1;
		assert (count == 0)
			$display("PASSED! Reset cleared count at time: %0t.", $time);
		else
			$error("FAILED! Reset did not clear count at time: %0t.", $time);
			
		// Test 2: counter counts up correctly when enabled
		reset = 0;
		enable = 1;
		repeat (3) @(posedge clk); #1;
		assert (count == 3)
			$display("PASSED! Counter counts up correctly while enabled at time: %0t.", $time);
		else
			$error("FAILED! Counter does not count up correctly while enabled at time: %0t.", $time);
			
		// Test 3: counter stops counting when disabled
		enable = 0;
		repeat (3) @(posedge clk); #1;
		assert (count == 3)
			$display("PASSED! Counter stops counting while disabled at time: %0t.", $time);
		else
			$error("FAILED! Counter does not stop counting while disabled at time: %0t.", $time);
			
		// Test 4: counter resumes when enabled again
		enable = 1;
		repeat (3) @(posedge clk); #1;
		assert (count == 6)
			$display("PASSED! Counter resumes when enabled again at time: %0t.", $time);
		else
			$error("FAILED! Counter does not resume when enabled again at time: %0t.", $time);
		
		// Test 5: Counter goes up to MAX_COUNT - 1
		repeat (4) @(posedge clk); #1;
		assert (count == MAX_COUNT - 1)
			$display("PASSED! Counter counts to MAX_COUNT-1 at time: %.0t.", $time);
		else
			$error("FAILED! Counter does not count to MAX_COUNT -1 at time: %.0t.", $time);
			
		// Test 6: Counter wraps back to 0 after MAX_COUNT-1
		@(posedge clk); #1;
		assert (count == 0)
			$display("PASSED! Count resets to 0 after wrapping at time: %0t.", $time);
		else
			$error("FAILED! Count does not reset to 0 after wrapping at time: %0t.", $time);
			
		// TEST 7: Counter resets to 0 during count-up
		repeat (4) @(posedge clk); #1;
		reset = 1;
		@(posedge clk); #1;
		assert (count == 0)
			$display("PASSED! Reset clears a nonzero count at time: %0t.", $time);
		else
			$error("FAILED! Reset did not clear a nonzero count at time: %0t.", $time);
			
		#100 $stop;
	
	end
	
endmodule