`timescale 1 ns/1 ns

module lab2_az_tb();
	logic [3:0]	s0, s1;
	logic		reset;
	logic [3:0]	col;
	logic [3:0]	led;
	logic [6:0]	seg;
	logic [1:0]	pnp;
	logic [3:0]	row;
	
	logic		key_a;	// key on row[3], column 2
	logic		key_b;	// key on row[2], column 1
	logic		key_c;	// key on row[0], column 1
	
	localparam	MUX_COUNT	= 192_000;
	localparam	SCAN_COUNT	= 12_000_000;
	
	lab2_az dut(s0, s1, reset, col, led, seg, pnp, row);
	
	// A pressed key pulls its column low while its own row is driven low by the open-collector transistor. Rest is high.
	assign col[0] = 1'b1;
	assign col[1] = ((key_b && row[2]) || (key_c && row[0])) ? 1'b0 : 1'b1;
	assign col[2] = (key_a && row[3]) ? 1'b0 : 1'b1;
	assign col[3] = 1'b1;
	
	// apply stimuli and check outputs
	initial begin
		key_a = 0;
		key_b = 0;
		key_c = 0;
		s0    = 4'h3;
		s1    = 4'hC;
		reset = 0;
		@(posedge dut.clk); #1;
	
		// Test 1: reset selects digit 1, which shows C
		assert (pnp == 2'b01 && seg == 7'b1000110)
			$display("PASSED! Reset selects digit 1 showing C at time: %0t.", $time);
		else
			$error("FAILED! After reset pnp = %b, seg = %b at time: %0t.", pnp, seg, $time);
			
		// Test 2: digit 1 stays selected for the first half of the refresh period
		reset = 1;
		repeat (MUX_COUNT / 2 - 1) @(posedge dut.clk); #1;
		assert (pnp == 2'b01 && seg == 7'b1000110)
			$display("PASSED! Digit 1 held through the first half of the period at time: %0t.", $time);
		else
			$error("FAILED! Digit 1 not held: pnp = %b, seg = %b at time: %0t.", pnp, seg, $time);
			
		// Test 3: the multiplexer switches to digit 0, showing 3
		@(posedge dut.clk); #1;
		assert (pnp == 2'b10 && seg == 7'b0110000)
			$display("PASSED! Digit 0 selected showing 3 at half period at time: %0t.", $time);
		else
			$error("FAILED! Digit 0 not selected: pnp = %b, seg = %b at time: %0t.", pnp, seg, $time);
			
		// Test 4: digit 0 stays selected for the second half of the refresh period
		repeat (MUX_COUNT / 2 - 1) @(posedge dut.clk); #1;
		assert (pnp == 2'b10 && seg == 7'b0110000)
			$display("PASSED! Digit 0 held through the second half of the period at time: %0t.", $time);
		else
			$error("FAILED! Digit 0 not held: pnp = %b, seg = %b at time: %0t.", pnp, seg, $time);
			
		// Test 5: the multiplexer wraps back to digit 1
		@(posedge dut.clk); #1;
		assert (pnp == 2'b01 && seg == 7'b1000110)
			$display("PASSED! Multiplexer wraps back to digit 1 at time: %0t.", $time);
		else
			$error("FAILED! Multiplexer did not wrap: pnp = %b, seg = %b at time: %0t.", pnp, seg, $time);
			
		// Test 6: the two digits are independent, change both switches
		s0 = 4'hF;
		s1 = 4'h0;
		#1;
		assert (pnp == 2'b01 && seg == 7'b1000000)
			$display("PASSED! Digit 1 updates to 0 at time: %0t.", $time);
		else
			$error("FAILED! Digit 1 shows seg = %b instead of 0 at time: %0t.", seg, $time);
			
		// Test 7: the first number follows its own switch
		repeat (MUX_COUNT / 2) @(posedge dut.clk); #1;
		assert (pnp == 2'b10 && seg == 7'b0001110)
			$display("PASSED! Digit 0 updates to F at time: %0t.", $time);
		else
			$error("FAILED! Digit 0 shows seg = %b instead of F at time: %0t.", seg, $time);
			
		// Test 8: reset restarts the keypad scan at 1000, with no key pressed no LED lights
		reset = 0;
		@(posedge dut.clk); #1;
		assert (row == 4'b1000 && led == 4'b0000)
			$display("PASSED! Reset starts the scan at 1000 with all LEDs off at time: %0t.", $time);
		else
			$error("FAILED! After reset row = %b, led = %b at time: %0t.", row, led, $time);
			
		// Test 9: press three keys at once, two of them sharing column 1.
		// The key on the row being scanned lights the LED.
		reset = 1;
		key_a = 1;
		key_b = 1;
		key_c = 1;
		#1;
		assert (led == 4'b0100)
			$display("PASSED! Key on row 1000 lights LED 2 at time: %0t.", $time);
		else
			$error("FAILED! Key on row 1000 gives led = %b at time: %0t.", led, $time);
			
		// Test 10: the scan moves on and the next key lights a different LED
		repeat (SCAN_COUNT / 4) @(posedge dut.clk); #1;
		assert (row == 4'b0100 && led == 4'b0010)
			$display("PASSED! Key on row 0100 lights LED 1 at time: %0t.", $time);
		else
			$error("FAILED! Row %b gives led = %b at time: %0t.", row, led, $time);
			
		// Test 11: a row with no key pressed leaves every LED off, so the LEDs blink
		repeat (SCAN_COUNT / 4) @(posedge dut.clk); #1;
		assert (row == 4'b0010 && led == 4'b0000)
			$display("PASSED! Row 0010 has no key pressed and all LEDs are off at time: %0t.", $time);
		else
			$error("FAILED! Row %b gives led = %b at time: %0t.", row, led, $time);
			
		// Test 12: the second key in column 1 lights the same LED on its own row,
		// which is the case that would short two row drivers without open-collector outputs
		repeat (SCAN_COUNT / 4) @(posedge dut.clk); #1;
		assert (row == 4'b0001 && led == 4'b0010)
			$display("PASSED! Second key in column 1 lights LED 1 on row 0001 at time: %0t.", $time);
		else
			$error("FAILED! Row %b gives led = %b at time: %0t.", row, led, $time);
			
		// Test 13: releasing the keys turns the LEDs off
		key_a = 0;
		key_b = 0;
		key_c = 0;
		#1;
		assert (led == 4'b0000)
			$display("PASSED! Releasing the keys turns all LEDs off at time: %0t.", $time);
		else
			$error("FAILED! Released keys give led = %b at time: %0t.", led, $time);
			
		#100 $stop;
	
	end

endmodule
