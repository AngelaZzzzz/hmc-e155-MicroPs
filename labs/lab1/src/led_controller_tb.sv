`timescale 1 ns/1 ns

module led_controller_tb();
	logic		clk;
	logic 		reset;
	logic		led;
	
	localparam	WIDTH		= 4;
	localparam	MAX_COUNT	= 10;
	
	led_controller #(WIDTH, MAX_COUNT) dut(clk, reset, led);
	
	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	// apply stimuli and check outputs
	initial begin
		#4
		reset = 1;
	
		// Test 1: reset the counter, expected led on
		#1;
		assert (led == 1'b1)
			$display("PASSED! Led is on after reset at time: %0t.", $time);
		else
			$error("FAILED! Led is not on after reset at time: %0t.", $time);
			
		// Test 2: led is high while count < (MAX_COUNT /2)
		reset = 0;
		repeat (MAX_COUNT / 2 - 1) @(posedge clk); #1;
		assert (led == 1'b1)
			$display("PASSED! Led is on through the first half of the period at time: %0t.", $time);
		else
			$error("FAILED! Led is not on through the first half of the period at time: %0t.", $time);
			
		// Test 3: led is low when count = (MAX_COUNT /2)
		@(posedge clk); #1;
		assert (led == 1'b0)
			$display("PASSED! Led is low when it reached half of the period at time: %0t.", $time);
		else
			$error("FAILED! Led is not low when it reached half of the period at time: %0t.", $time);
			
		// Test 4: led is low while count > (MAX_COUNT /2)
		repeat (MAX_COUNT / 2 - 1) @(posedge clk); #1;
		assert (led == 1'b0)
			$display("PASSED! Led is low through the second half of the period at time: %0t.", $time);
		else
			$error("FAILED! Led is not low through the second half of the period at time: %0t.", $time);
			
		// Test 5: led is high when counter wraps
		@(posedge clk); #1;
		assert (led == 1'b1)
			$display("PASSED! Led is on after wrapping at time: %0t.", $time);
		else
			$error("FAILED! Led is not on after wrapping at time: %0t.", $time);
			
		#100 $stop;
	
	end

endmodule
