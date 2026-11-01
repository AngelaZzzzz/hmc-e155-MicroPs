// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	10/30/2026
//
// Purpose: ShiftRows (FIPS-197 5.1.2). Row 1 is shifted left by 0 bytes, row 2 is shfited
// left by 1 byte, row 3 by 2 bytes, and row 4 by 4 bytes. All bytes shifted out wraps around.

module shift_rows(
	input	logic [127:0]	a,
	output	logic [127:0]	y
);

	assign y = {a[127:120], a[87:80],   a[47:40],   a[7:0],
	           a[95:88],   a[55:48],   a[15:8],    a[103:96],
	           a[63:56],   a[23:16],   a[111:104], a[71:64],
	           a[31:24],   a[119:112], a[79:72],   a[39:32]};

endmodule
