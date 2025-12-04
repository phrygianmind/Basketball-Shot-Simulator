`timescale 1ns / 1ps
// top_accel - top module for accelerometer
// Author(s): Benjamin T
// combines design modules for accelerometer

module top_accel(
    input  wire        CLK100MHZ,
    input  wire        BTN_FREEZE,   
    input  wire        ACL_MISO,
    output wire        ACL_MOSI,
    output wire        ACL_SCLK,
    output wire        ACL_CSN,
    output wire [14:0] LED,
    output wire [6:0]  SEG,
    output wire        DP,
    output wire [7:0]  AN
);

  wire        w_4MHz;
  wire [15:0] x_raw;
  wire        x_valid; 
  wire        btn_db;
  wire [15:0] x_disp;

  // shot flick magnitude 
  wire [15:0] flick_mag;
  

  // clock divider
  iclk_genr u_clk (
    .CLK100MHZ (CLK100MHZ),
    .clk_4MHz  (w_4MHz)
  );

  // SPI to ADXL362 (X-only)
  spi_master u_spi (
    .iclk     (w_4MHz),
    .miso     (ACL_MISO),
    .sclk     (ACL_SCLK),
    .mosi     (ACL_MOSI),
    .cs       (ACL_CSN),
    .x_raw    (x_raw),
    .x_valid  (x_valid)
  );

  // filter x for shot motion
shot_filter u_flick (
  .clk(w_4MHz), 
  .rst(1'b0), 
  .x_valid(x_valid), 
  .x_raw(x_raw), 
  .flick(flick_mag)
);

  // button debounce (freeze)
  btn_sync u_db (
    .clk    (CLK100MHZ),
    .btn_in (BTN_FREEZE),
    .btn_db (btn_db)
  );

  // 7-seg debug shows either live or frozen (now using flick)
  seg7_xraw u_seg (
    .CLK100MHZ (CLK100MHZ),
    .x_raw     (x_disp),
    .seg       (SEG),
    .dp        (DP),
    .an        (AN)
  );

  // edge detect for freeze button
  reg btn_db_d;
  always @(posedge CLK100MHZ) btn_db_d <= btn_db;
  wire btn_rise = btn_db & ~btn_db_d;  // single-cycle on press

  // freeze sample and display mux (freeze the flick value)
  reg [15:0] x_freeze;
  always @(posedge CLK100MHZ) begin
    if (btn_rise) x_freeze <= flick_mag;
  end

  assign x_disp = btn_db ? x_freeze : flick_mag;

  // LEDs mirror display value (also freeze)
  assign LED[14:10] = x_disp[14:10];
  assign LED[9:5]   = x_disp[9:5];
  assign LED[4:0]   = x_disp[4:0];

endmodule
