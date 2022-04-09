`default_nettype	none
//
module ufifo #(
	parameter integer WIDTH = 8,
	parameter integer AWIDTH = 2
) (
	input wire i_clk,
	input wire i_reset,
	// write interface
	input wire i_wr,
	input wire [WIDTH - 1:0] i_data,
	// read interface
	input wire i_rd,
	output wire [WIDTH - 1:0] o_data,

	output reg [AWIDTH - 1:0] o_used,
	output reg [AWIDTH - 1:0] o_empty,
	output reg will_underflow,
	output reg will_overflow,
	output wire o_half_full,
	output wire o_half_empty,
	output wire o_err
);
	// RAM
	reg [WIDTH - 1 : 0] fifo[0 : (1 << AWIDTH) - 1];

	reg [AWIDTH - 1 : 0] wr_addr;
	reg [AWIDTH - 1 : 0] rd_addr;

	wire [AWIDTH - 1:0] wr_addr_next;
	assign wr_addr_next = wr_addr + 1;

	wire [AWIDTH - 1:0] wr_addr_next_next;
	assign wr_addr_next_next = wr_addr + 2;

	initial will_overflow = 0;
	always @(posedge i_clk)
	if (i_reset)
		will_overflow <= 0;
	else
		will_overflow <= (i_wr || !i_rd) && will_overflow ||
			!i_rd && (!i_wr && (wr_addr_next == rd_addr) ||
				   i_wr && (wr_addr_next_next == rd_addr));

	wire w_write;
	assign w_write = i_wr && (!will_overflow || i_rd);

	initial wr_addr = 0;
	always @(posedge i_clk)
	if (i_reset)
		wr_addr <= 0;
	else if (w_write) begin
		wr_addr <= wr_addr_next;
		fifo[wr_addr] <= i_data;
	end

	wire underflow = will_underflow || i_rd && (rd_addr_next == wr_addr);
	initial will_underflow = 1;
	always @(posedge i_clk)
	if (i_reset)
		will_underflow <= 1;
	else
		will_underflow <= !i_wr && underflow; 

	wire w_read;
	assign w_read  = i_rd && !will_underflow;

	wire need_bypass;
	assign need_bypass = i_wr && underflow;

	initial rd_addr = 0;
	reg [WIDTH - 1 : 0] fifo_data;
	reg [WIDTH - 1 : 0] bypass_data;
	reg [AWIDTH - 1 : 0] rd_addr_next;
	initial rd_addr_next  = 1;
	always @(posedge i_clk)
	if (i_reset) begin
		rd_addr <= 0;
		rd_addr_next  <= 1;
	end else if (w_read) begin
		rd_addr <= rd_addr_next;
		rd_addr_next  <= rd_addr_next + 1;
		fifo_data <= fifo[rd_addr_next[AWIDTH-1:0]];
	end

	always @(posedge i_clk)
	if (need_bypass)
		bypass_data <= i_data;

	reg use_bypass;
	initial	use_bypass = 0;
	always @(posedge i_clk)
	if (i_reset)
		use_bypass <= 0;
	else if (need_bypass)
		use_bypass <= 1;
	else if (i_rd)
		use_bypass <= 0;

	assign o_data = (use_bypass) ? bypass_data : fifo_data;

	initial o_used = 0;
	always @(posedge i_clk)
	if (i_reset)
		o_used <= 0;
	else if(!w_write && w_read)
		o_used <= o_used - 1'b1;
	else if (w_write && !w_read)
		o_used <= o_used + 1'b1;

	initial	o_empty = -1;
	always @(posedge i_clk)
	if (i_reset)
		o_empty <= -1;
	else if (!w_write && w_read)
		o_empty <= o_empty + 1'b1;
	else if (w_write && !w_read)
		o_empty <= o_empty - 1'b1;

	assign o_err = i_wr && !i_rd && will_overflow;
	assign o_half_empty = o_empty[(AWIDTH-1)];
	assign o_half_full = o_used[(AWIDTH-1)];

`ifdef	FORMAL
	reg	f_past_valid;

	initial	f_past_valid = 0;
	always @(posedge i_clk)
		f_past_valid <= 1;

	////////////////////////////////////////////////////////////////////////
	//
	// Pointer checks
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	[AWIDTH-1:0]	f_fill;
	wire	[AWIDTH-1:0]	f_raddr_plus_one;

	always @(*)
		f_fill = wr_addr - rd_addr;

	always @(*)
		assert(will_underflow == (f_fill == 0));

	always @(*)
		assert(will_overflow  == (&f_fill));

	assign	f_raddr_plus_one = rd_addr + 1;

	always @(*)
		assert(f_raddr_plus_one  == rd_addr_next);

	always @(*)
	if (will_underflow)
	begin
		assert(!w_read);
		assert(!use_bypass);
	end


	always @(posedge i_clk) begin
		assert(o_used == f_fill);
		assert(o_empty == (~f_fill));
	end

	////////////////////////////////////////////////////////////////////////
	//
	// Twin write check
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
`ifdef	UFIFO
	(* anyconst *) reg [AWIDTH-1:0] f_const_addr;
	(* anyconst *) reg [WIDTH-1:0] f_const_data, f_const_second;
	reg [AWIDTH-1:0] f_next_addr;
	reg [1:0] f_state;
	reg f_first_in_fifo, f_second_in_fifo;
	reg [AWIDTH-1:0] f_distance_to_first, f_distance_to_second;

	always @(*)
	begin
		f_next_addr = f_const_addr + 1;

		f_distance_to_first  = f_const_addr - rd_addr;
		f_distance_to_second = f_next_addr  - rd_addr;

		f_first_in_fifo  = (f_distance_to_first  < f_fill)
			&& !will_underflow
			&& (fifo[f_const_addr] == f_const_data);
		f_second_in_fifo = (f_distance_to_second < f_fill)
			&& !will_underflow
			&& (fifo[f_next_addr] == f_const_second);
	end

	initial	f_state = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_state <= 0;
	else case(f_state)
	0: if (w_write && (wr_addr == f_const_addr) && (i_data == f_const_data))
		f_state <= 1;
	1: if (w_read && (rd_addr == f_const_addr))
			f_state <= 0;
		else if (w_write && (wr_addr == f_next_addr))
			f_state <= (i_data == f_const_second) ? 2 : 0;
	2: if (w_read && (rd_addr == f_const_addr))
			f_state <= 3;
	3: if (w_read)
			f_state <= 0;
	endcase

	always @(*)
	case(f_state)
	0: begin end
	1: begin
		assert(!will_underflow);
		assert(f_first_in_fifo);
		assert(!f_second_in_fifo);
		assert(wr_addr == f_next_addr);
		assert(fifo[f_const_addr] == f_const_data);
		if (rd_addr == f_const_addr)
			assert(o_data == f_const_data);
		end
	2: begin
		assert(f_first_in_fifo);
		assert(f_second_in_fifo);
		end
	3: begin
		assert(f_second_in_fifo);
		assert(rd_addr == f_next_addr);
		assert(o_data  == f_const_second);
		end
	endcase
`endif
	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	cvr_filled;

	always @(*)
		cover(!will_underflow);

`ifdef	UFIFO
	always @(*)
		cover(o_err);

	initial	cvr_filled = 0;
	always @(posedge i_clk)
	if (i_reset)
		cvr_filled <= 0;
	else if (&f_fill[AWIDTH-1:0])
		cvr_filled <= 1;

	always @(*)
		cover(cvr_filled && will_underflow);
`endif // UFIFO
`endif
endmodule
