`timescale 1ns / 1ps
// top_accel - top module for acclerometer
// Author(s): Benjamin T, Toby P, Kevin L
// combines design modules for accelerometer

module top_accel(
    input  wire        CLK100MHZ,
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
  wire        x_valid; // optional

// module instantiation

iclk_genr u_clk (
  .CLK100MHZ (CLK100MHZ),
  .clk_4MHz  (w_4MHz)
);

spi_master u_spi (
  .iclk     (w_4MHz),
  .miso     (ACL_MISO),
  .sclk     (ACL_SCLK),
  .mosi     (ACL_MOSI),
  .cs       (ACL_CSN),
  .x_raw    (x_raw),      // <-- connect new port from spi_master
  .x_valid  (x_valid)     // <-- optional
);

  // debug module (remove later for shot-clock implementation)

seg7_xraw u_seg (
  .CLK100MHZ (CLK100MHZ),
  .x_raw     (x_raw),     // <-- use x_raw, not acl_data
  .seg       (SEG),
  .dp        (DP),
  .an        (AN)
);
  // LEDs: X[14:10], Y[9:5], Z[4:0]
  assign LED[14:10] = x_raw[14:10];
  assign LED[9:5]   = x_raw[9:5];
  assign LED[4:0]   = x_raw[4:0];
endmodule
