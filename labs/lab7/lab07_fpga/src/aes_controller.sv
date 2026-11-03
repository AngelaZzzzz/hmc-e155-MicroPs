// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	10/30/2026
//
// Purpose: Canonical FSM that sequences the 10 AES rounds. Each round spends one cycle in
//			SUB waiting for the sbox RAM and one cycle in EXECUTE running the
//			rest of the round and writing the round registers.

module aes_controller(
	input	logic		clk,
	input	logic		load,
	output	logic		en,
	output	logic		key_sel,
	output	logic [1:0]	data_sel,
	output	logic [7:0]	rcon,
	output	logic		done
);

	typedef enum logic [1:0] {LOAD, SUB, EXECUTE, DONE} state_type;

	state_type		state, next_state;
	logic [3:0]		round;
	logic			last;
	
	// Next state logic
	always_comb
		if (load) next_state = LOAD;
		else
			case (state)
				LOAD:		next_state = SUB;
				SUB:		next_state = EXECUTE;
				EXECUTE:	if (last) next_state = DONE;
							else      next_state = SUB;
				default:	next_state = DONE;
			endcase

	// State register
	always_ff @(posedge clk)
		state <= next_state;

	// Output logic
	assign en       = (state == LOAD) || (state == EXECUTE);
	assign key_sel  = (state == LOAD);
	assign data_sel = (state == LOAD) ? 2'b00 : last ? 2'b10 : 2'b01;
	assign done     = (state == DONE);

	// Counter for rounds
	always_ff @(posedge clk)
		if (state == LOAD)         round <= 4'd1;
		else if (state == EXECUTE) round <= round + 4'd1;

	assign last = (round == 4'd10);

	// Round constant according to the round
	always_comb
		case (round)
			4'd1:    rcon = 8'h01;
			4'd2:    rcon = 8'h02;
			4'd3:    rcon = 8'h04;
			4'd4:    rcon = 8'h08;
			4'd5:    rcon = 8'h10;
			4'd6:    rcon = 8'h20;
			4'd7:    rcon = 8'h40;
			4'd8:    rcon = 8'h80;
			4'd9:    rcon = 8'h1b;
			4'd10:   rcon = 8'h36;
			default: rcon = 8'h00;
		endcase

endmodule
