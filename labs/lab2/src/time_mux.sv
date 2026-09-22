// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/11/2026
//
// Purpose: This is the time multiplexer for the dual 7-segment display. For the first half 
//			of each count period digit 0 is selected, for the second half digit 1 is selected.
//			The selected value is sent to the seven_segment_decoder and only the matching anode
//			is enabled. This time multiplexer multiplexes at a rate of 125 Hz, making
//			switching between displays invisible to the human eye.

module time_mux #(
	parameter	WIDTH		= 18,
	parameter	MAX_COUNT	= 192_000
)(
	input	logic		clk,
	input	logic		reset,
	input	logic [3:0]	s0,
	input	logic [3:0]	s1,
	output	logic [3:0]	s_eff,
	output	logic [1:0]	pnp
);

	logic [WIDTH-1:0]	count;
	logic				select;

	counter #(WIDTH, MAX_COUNT) counter(clk, reset, 1'b1, count);

	// Select signal: 0 for first half of the period, 1 for second half
	assign select = (count < (MAX_COUNT / 2));

	// 2:1 multiplexer in front of the shared decoder
	assign s_eff = select ? s1 : s0;

	// one anode is on at a time
	assign pnp[0] = select;
	assign pnp[1] = ~select;

endmodule
