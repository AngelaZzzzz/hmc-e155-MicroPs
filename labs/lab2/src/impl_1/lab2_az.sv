// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/11/2026
//
// Purpose: This is the top level module of E155 lab 2. This module instantiates the
//			internal oscillator, time multiplexer, a switch-to-7-segment decoder, 
//			a keypad row scanner, and drives four leds that represent the keypad scanner.
 
module lab2_az(	
	input	logic [3:0] s0,
	input 	logic [3:0] s1,
	input	logic		reset,
	input 	logic [3:0] col,
	output	logic [3:0]	led,
	output	logic [6:0]	seg,
	output	logic [1:0]	pnp,
	output 	logic [3:0]	row
);

	logic clk;
	logic [3:0] s_eff;
	     
	// Internal high-speed oscillator
	HSOSC hf_osc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

	// Time multiplexer, 48 MHz / 192000 / 2 = 125 Hz
	time_mux #(18, 192_000) mux(clk, ~reset, s0, s1, s_eff, pnp);
	
	// Switch-to-7-segment decoder
	seven_segment_decoder decoder(s_eff, seg);

	// Keypad row scanner
	keypad_scanner #(24, 12_000_000) scanner(clk, ~reset, 1'b1, row);
	
	// LED assignment from active row
	assign led = ~col;
			
endmodule