// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/7/2026
//
// Purpose: This blinker module outputs a 2.4 Hz blink signal from a 48 MHz clock.

module led_controller #(
	parameter	WIDTH		= 25,
	parameter	MAX_COUNT	= 20_000_000
)(
	input	logic clk,
	input 	logic reset,
	output	logic led
);

	logic [WIDTH-1:0] count;

	// Counter module that outputs 2.4 Hz
	counter #(WIDTH, MAX_COUNT) counter(clk, reset, 1'b1, count);

	assign led = (count < (MAX_COUNT /2));
	
endmodule