`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [0:0] PI_i_rd;
  reg [7:0] PI_i_data;
  reg [0:0] PI_i_wr;
  reg [0:0] PI_i_clk;
  reg [0:0] PI_i_reset;
  ufifo UUT (
    .i_rd(PI_i_rd),
    .i_data(PI_i_data),
    .i_wr(PI_i_wr),
    .i_clk(PI_i_clk),
    .i_reset(PI_i_reset)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$formal$ufifo.v:163$7_CHECK = 1'b0;
    // UUT.$formal$ufifo.v:163$7_EN = 1'b0;
    // UUT.$formal$ufifo.v:164$8_CHECK = 1'b0;
    UUT.bypass_data = 8'b00000000;
    UUT.cvr_filled = 1'b0;
    UUT.f_state = 2'b00;
    UUT.fifo_data = 8'b00000000;
    UUT.o_empty = 2'b11;
    UUT.o_used = 2'b00;
    UUT.rd_addr = 2'b00;
    UUT.rd_addr_next = 2'b01;
    UUT.use_bypass = 1'b0;
    UUT.will_overflow = 1'b0;
    UUT.will_underflow = 1'b1;
    UUT.wr_addr = 2'b00;
    UUT.f_const_addr = 2'b00;
    UUT.f_const_second = 8'b00000000;
    UUT.f_const_data = 8'b00000000;
    UUT.fifo[2'b01] = 8'b00000000;
    UUT.fifo[2'b00] = 8'b00000000;
    UUT.fifo[2'b10] = 8'b00000000;
    UUT.fifo[2'b11] = 8'b00000000;

    // state 0
    PI_i_rd = 1'b0;
    PI_i_data = 8'b00000000;
    PI_i_wr = 1'b1;
    PI_i_clk = 1'b0;
    PI_i_reset = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_i_rd <= 1'b0;
      PI_i_data <= 8'b00000000;
      PI_i_wr <= 1'b1;
      PI_i_clk <= 1'b0;
      PI_i_reset <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_i_rd <= 1'b0;
      PI_i_data <= 8'b00000000;
      PI_i_wr <= 1'b1;
      PI_i_clk <= 1'b0;
      PI_i_reset <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_i_rd <= 1'b1;
      PI_i_data <= 8'b00000000;
      PI_i_wr <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_reset <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_i_rd <= 1'b1;
      PI_i_data <= 8'b00000000;
      PI_i_wr <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_reset <= 1'b0;
    end

    // state 5
    if (cycle == 4) begin
      PI_i_rd <= 1'b1;
      PI_i_data <= 8'b00000000;
      PI_i_wr <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_reset <= 1'b0;
    end

    // state 6
    if (cycle == 5) begin
      PI_i_rd <= 1'b0;
      PI_i_data <= 8'b00000000;
      PI_i_wr <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_reset <= 1'b0;
    end

    genclock <= cycle < 6;
    cycle <= cycle + 1;
  end
endmodule
