`timescale 1ns / 1ps
// top_accel - top module for accelerometer
// Author(s): Benjamin T
// combines design modules for accelerometer
// now indcludes both x and y values
// btn_sync.v, iclk_genr.v, and constraint file still required


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
    output wire [7:0]  AN,
    output wire [15:0] x_out,
    output wire [15:0] y_out
);

  wire        w_4MHz;

  // X + Y raw from SPI
  wire [15:0] x_raw;
  wire        x_valid; 
  wire [15:0] y_raw;
  wire        y_valid;
  assign x_out = x_raw;
  assign y_out = y_raw;
  // filtered flick magnitudes
  wire [15:0] x_flick;
  wire [15:0] y_flick;

  // freeze plumbing
  wire        btn_db;
  reg  [15:0] x_freeze, y_freeze;
  wire [15:0] x_disp,   y_disp;

  // clock divider
  iclk_genr u_clk (
    .CLK100MHZ (CLK100MHZ),
    .clk_4MHz  (w_4MHz)
  );

  // SPI to ADXL362 (X+Y burst)
  spi_master u_spi (
    .iclk     (w_4MHz),
    .miso     (ACL_MISO),
    .sclk     (ACL_SCLK),
    .mosi     (ACL_MOSI),
    .cs       (ACL_CSN),
    .x_raw    (x_raw),
    .x_valid  (x_valid),
    .y_raw    (y_raw),
    .y_valid  (y_valid)
  );

  // dual-axis shot flick filter 
  shot_filter_xy #(.ALPHA_SHIFT(3)) u_flick_xy (
    .clk     (w_4MHz),
    .rst     (1'b0),
    .x_valid (x_valid),
    .x_raw   (x_raw),
    .x_flick (x_flick),
    .y_valid (y_valid),
    .y_raw   (y_raw),
    .y_flick (y_flick)
  );

  // button debounce (freeze)
  btn_sync u_db (
    .clk    (CLK100MHZ),
    .btn_in (BTN_FREEZE),
    .btn_db (btn_db)
  );

  // edge detect for freeze button
  reg btn_db_d;
  always @(posedge CLK100MHZ) btn_db_d <= btn_db;
  wire btn_rise = btn_db & ~btn_db_d;  // single-cycle on press

  // freeze both flick values at press
  always @(posedge CLK100MHZ) begin
    if (btn_rise) begin
      x_freeze <= x_flick;
      y_freeze <= y_flick;
    end
  end

  // display muxes (live vs frozen)
  assign x_disp = btn_db ? x_freeze : x_flick;
  assign y_disp = btn_db ? y_freeze : y_flick;

    // 7-seg shows Y on left segment, X on right segment (4 digits each)
  seg7_xy u_seg (
    .CLK100MHZ (CLK100MHZ),
    .x_raw     (y_disp),   // <-- feed Y here (left side)
    .y_raw     (x_disp),   // <-- feed X here (right side)
    .seg       (SEG),
    .dp        (DP),
    .an        (AN)
  );
    
    
endmodule
