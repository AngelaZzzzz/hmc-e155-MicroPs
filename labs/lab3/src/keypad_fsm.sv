// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/26/2026
//
// Purpose: Canonical FSM for reading the keypad, communicating with the row scanner and a
//					debounce timer

module keypad_fsm #(
	parameter	WIDTH		 = 20,
	parameter	DEBOUNCE_MAX = 960_000
)(
	input	logic		clk,
	input	logic		reset,
	input	logic [3:0]	col_sync,
	output	logic		scan_enable,
	output	logic		key_valid
);
 
	typedef enum logic [2:0] {SCAN, DEBOUNCE, CHECK, REGISTER, HOLD, MULTI, RELEASE} state_t;
 
	state_t				state, next_state;
	logic [WIDTH-1:0]	count;
	logic				timer_run, timer_done, pressed, one_key;
	logic [3:0]			keys;
 
	// Debounce timer
	counter #(WIDTH, DEBOUNCE_MAX) debounce_timer(clk, reset, timer_run, count);
 
	assign timer_done = (count == DEBOUNCE_MAX - 1);
 
	// Column status
	assign keys    = ~col_sync;
	assign pressed = |keys;
	assign one_key = pressed && ((keys & (keys - 4'b1)) == 4'b0);
 
	// State register
	always_ff @(posedge clk, posedge reset) begin
		if (reset) state <= SCAN;
		else       state <= next_state;
	end
 
	// Next state logic
	always_comb begin
		case (state)
			SCAN:		if (pressed)         next_state = DEBOUNCE;
						else                 next_state = SCAN;
			DEBOUNCE:	if (timer_done)      next_state = CHECK;
						else                 next_state = DEBOUNCE;
			CHECK:		if (one_key)         next_state = REGISTER;
						else if (pressed)    next_state = MULTI;
						else                 next_state = SCAN;
			REGISTER:	                     next_state = HOLD;
			HOLD:		if (!pressed)        next_state = RELEASE;
						else if (!one_key)   next_state = MULTI;
						else                 next_state = HOLD;
			MULTI:		if (!pressed)        next_state = RELEASE;
						else if (one_key)    next_state = DEBOUNCE;
						else                 next_state = MULTI;
			RELEASE:	if (!timer_done)     next_state = RELEASE;
						else if (pressed)    next_state = HOLD;
						else                 next_state = SCAN;
			default:	                     next_state = SCAN;
		endcase
	end
 
	// Output logic
	assign scan_enable = (state == SCAN);
	assign timer_run   = (state == DEBOUNCE) || (state == RELEASE);
	assign key_valid   = (state == REGISTER);
 
endmodule