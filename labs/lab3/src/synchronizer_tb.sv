// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: Testbench for synchronizer. Checks that an input change appears at the output
//			exactly two clock edges later and never earlier, for several input patterns.

`timescale 1 ns/1 ns

module synchronizer_tb();
	logic		clk;
	logic [3:0]	d;
	logic [3:0]	q;

	synchronizer #(4) dut(clk, d, q);

	// generate a clock
	always begin
		clk = 0; #5;
		clk = 1; #5;
	end

	// apply stimuli and check outputs
	initial begin
		#2
		d = 4'b1111;
		repeat (2) @(posedge clk); #1;

		// Test 1: idle value propagates through both flops
		assert (q == 4'b1111)
			$display("PASSED! Idle value 1111 reaches q after two edges at time: %0t.", $time);
		else
			$error("FAILED! q is %b instead of 1111 after two edges at time: %0t.", q, $time);

		// Test 2: a change on d does not reach q after one edge
		d = 4'b1010;
		@(posedge clk); #1;
		assert (q == 4'b1111)
			$display("PASSED! q still 1111 one edge after d changed at time: %0t.", $time);
		else
			$error("FAILED! q changed to %b after only one edge at time: %0t.", q, $time);

		// Test 3: the change reaches q after the second edge
		@(posedge clk); #1;
		assert (q == 4'b1010)
			$display("PASSED! q follows d to 1010 after two edges at time: %0t.", $time);
		else
			$error("FAILED! q is %b instead of 1010 after two edges at time: %0t.", q, $time);

		// Test 4: a one-clock pulse on d is passed through intact, two edges late
		d = 4'b0101;
		@(posedge clk); #1;
		d = 4'b1010;
		@(posedge clk); #1;
		assert (q == 4'b0101)
			$display("PASSED! One-clock pulse 0101 appears at q at time: %0t.", $time);
		else
			$error("FAILED! q is %b instead of 0101 at time: %0t.", q, $time);

		// Test 5: and is gone one edge later
		@(posedge clk); #1;
		assert (q == 4'b1010)
			$display("PASSED! q returns to 1010 after the pulse at time: %0t.", $time);
		else
			$error("FAILED! q is %b instead of 1010 after the pulse at time: %0t.", q, $time);

		// Test 6: a change between edges is not seen until the next edge
		#3; d = 4'b0000; #1;
		assert (q == 4'b1010)
			$display("PASSED! q ignores d between edges at time: %0t.", $time);
		else
			$error("FAILED! q changed to %b without a clock edge at time: %0t.", q, $time);

		#100 $stop;
	end

endmodule
