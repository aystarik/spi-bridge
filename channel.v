`default_nettype	none
module spi_simple (
	// SPI pads
	input  wire spi_mosi,
	output wire spi_miso,
	input  wire spi_cs_n,
	input  wire spi_clk,

	// Interface
	output wire [7:0] addr,
	output wire [7:0] data,
	output reg  first,
	output reg  last,
	output wire strobe,

	input  wire [7:0] out,

	// Clock / Reset
	input  wire  clk,
	input  wire  rst
);
endmodule

module spi_simple_io_in (
	input  wire pad,
	output wire val,
	output wire rise,
	output wire fall,
	input  wire clk,
	input  wire rst
);
	// Signals
	wire iob_out_f, iob_out_b;

	// IOB
	SB_IO #(
		.PIN_TYPE(6'b000000),
		.PULLUP(1'b0),
		.NEG_TRIGGER(1'b0),
		.IO_STANDARD("SB_LVCMOS")
	) cs_n_iob_I (
		.PACKAGE_PIN(pad),
		.CLOCK_ENABLE(1'b1),
		.INPUT_CLK(clk),
//		.OUTPUT_CLK(1'b0),
		.OUTPUT_ENABLE(1'b0),
		.D_OUT_0(1'b0),
		.D_OUT_1(1'b0),
		.D_IN_0(iob_out_f),
		.D_IN_1(iob_out_b)
	);

	assign val = iob_out_b || iob_out_f;
	assign rise = iob_out_b && ~iob_out_f;
	assign fall = ~iob_out_b && iob_out_f;

endmodule // spi_simple_io_in


module spi_simple_io_out (
	output wire pad,
	input  wire val,
	input  wire oe,
	input  wire clk,
	input  wire rst
);

	SB_IO #(
		.PIN_TYPE(6'b101001),
		.PULLUP(1'b0),
		.NEG_TRIGGER(1'b0),
		.IO_STANDARD("SB_LVCMOS")
	) miso_iob_I (
		.PACKAGE_PIN(pad),
		.CLOCK_ENABLE(1'b1),
		.INPUT_CLK(clk),
		.OUTPUT_CLK(1'b0),
		.OUTPUT_ENABLE(oe),
		.D_OUT_0(val),
		.D_OUT_1(1'b0),
		.D_IN_0(),
		.D_IN_1()
	);

endmodule // spi_simple_io_out
