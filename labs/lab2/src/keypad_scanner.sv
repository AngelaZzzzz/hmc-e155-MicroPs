// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/14/2026
//
// Purpose: This is a keypad row scanner, which scans the keypad for any depressed key.
//			This circuit has four outputs that rotate between 1000, 0100, 0010, and 0001
//			Such that each bit toggles at a rate of 2 Hz.

module keypad_scanner #(
	parameter	WIDTH		= 24,
	parameter	MAX_COUNT	= 12_000_000
)(
	input	logic		clk,
	input	logic		reset,
	input	logic		enable,
	output	logic [3:0]	row
);
 
	logic [WIDTH-1:0] count;
 
	// State register and state update logic
	counter #(WIDTH, MAX_COUNT) scan_counter(clk, reset, enable, count);
 
	// Output logic
	//assign row = 4'b1111;
	assign row[3] = (count <  MAX_COUNT / 4);
	assign row[2] = (count >= MAX_COUNT / 4) && (count <     MAX_COUNT / 2);
	assign row[1] = (count >= MAX_COUNT / 2) && (count < 3 * MAX_COUNT / 4);
	assign row[0] = (count >= 3 * MAX_COUNT / 4);
 
endmodule
