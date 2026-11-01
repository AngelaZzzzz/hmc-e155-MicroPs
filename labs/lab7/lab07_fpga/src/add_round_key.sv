// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	10/30/2026
//
// Purpose: AddRoundKey (FIPS-197 5.1.4). XORs the state with the round key.

module add_round_key(
	input	logic [127:0]	a,
	input	logic [127:0]	round_key,
	output	logic [127:0]	y
);

	assign y = a ^ round_key;

endmodule
