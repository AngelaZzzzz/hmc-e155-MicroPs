// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: Top level module of E155 lab 3. Reads a 4x4 matrix keypad and shows the last
//					two hex digits pressed on the dual seven-segment display, newest digit on the
//					right.

module lab3_az(
	input	logic		reset,
	input	logic [3:0]	col,
	output	logic [3:0]	row,
	output	logic [6:0]	seg,
	output	logic [1:0]	pnp
);
 
	localparam SCAN_WIDTH   = 19;
	localparam SCAN_MAX     = 480_000;	// 48 MHz / 480,000 = 2.5 ms per row
	localparam DEBOUNCE_WIDTH = 20;
	localparam DEBOUNCE_MAX   = 960_000;	// 20 ms
	localparam MUX_WIDTH    = 18;
	localparam MUX_MAX      = 192_000;	// 48 MHz / 192,000 / 2 = 125 Hz per display
 
	logic		clk, rst, scan_enable, key_valid;
	logic		dbg_debounce, dbg_hold, dbg_release;
	logic [3:0]	col_sync, key, digit_left, digit_right, s_eff;

	assign rst = ~reset;
 
	// Internal high-speed oscillator (48 MHz)
	HSOSC hf_osc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));
 
	// Keypad: synchronize columns, scan rows, find and debounce a key
	synchronizer #(4) col_synchronizer(clk, col, col_sync);
	keypad_scanner #(SCAN_WIDTH, SCAN_MAX) scanner(clk, rst, scan_enable, row);
	keypad_fsm #(DEBOUNCE_WIDTH, DEBOUNCE_MAX) fsm(clk, rst, col_sync, scan_enable, key_valid);
 
	// Decode the held key (inputs made active high) and shift it into the display
	key_decoder decoder_key(row, ~col_sync, key);

	digit_register digits(clk, rst, key_valid, key, digit_left, digit_right);

	time_mux #(MUX_WIDTH, MUX_MAX) mux(clk, rst, digit_left, digit_right, s_eff, pnp);

	seven_segment_decoder decoder_seg(s_eff, seg);
 
endmodule