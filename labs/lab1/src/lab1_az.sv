// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/7/2026
//
// Purpose: This is the top level module of E155 lab 1. This module instantiates the
//				internal oscillator, led controller, and switch-to-7-segment decoder, and drives
// 			three leds that represent the binary encoding of a hex number inputted by
//				a switch.
 
module lab1_az(	
	input	logic [3:0] s,
	input	logic		reset,
	output	logic [2:0]	led,
	output	logic [6:0]	seg,
	output	logic		clk
);

	// logic clk;
	
	// Internal high-speed oscillator
	HSOSC hf_osc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));
	
	// LED controller that uses Counter module
	led_controller #(25, 20_000_000) led2(clk, ~reset, led[2]);
	
	// Switch-to-7-segment decoder
	seven_segment_decoder decoder(s, seg);
	
	// Switch to LED assignments
	assign led[0] = s[1] ^ s[0];
	assign led[1] = s[3] & s[2];
			
endmodule