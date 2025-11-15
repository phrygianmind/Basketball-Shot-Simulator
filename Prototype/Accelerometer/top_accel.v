`timescale 1ns / 1ps
// top_accel - top module for accelerometer
// Author(s): Benjamin T
// combines design modules for accelerometer

// top_accel 
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
  wire btn_db;

// module instantiation

  // clock divider module
  iclk_genr u_clk (
    .CLK100MHZ (CLK100MHZ),
    .clk_4MHz  (w_4MHz)
  );

  // SPI to ADXL362 module
  spi_master u_spi (
    .iclk     (w_4MHz),
    .miso     (ACL_MISO),
    .sclk     (ACL_SCLK),
    .mosi     (ACL_MOSI),
    .cs       (ACL_CSN),
    .x_raw    (x_raw),
    .x_valid  (x_valid)
  );

// button module
  debounce_btn u_db (
    .clk    (CLK100MHZ),
    .btn_in (BTN_FREEZE),
    .btn_db (btn_db)
  );



  // 7-seg debug shows either live or frozen
  seg7_xraw u_seg (
    .CLK100MHZ (CLK100MHZ),
    .x_raw     (x_disp),
    .seg       (SEG),
    .dp        (DP),
    .an        (AN)
  );

  reg btn_db_d;
  always @(posedge CLK100MHZ) btn_db_d <= btn_db;
  wire btn_rise = btn_db & ~btn_db_d;  // single-cycle on press

  // freeze sample and display mux 
  reg [15:0] x_freeze;
  always @(posedge CLK100MHZ) begin
    // capture the value at the moment the button is pressed
    if (btn_rise) x_freeze <= x_raw;       
  end

  wire [15:0] x_disp = btn_db ? x_freeze : x_raw;

  // LEDs mirror display value (also freeze)
  assign LED[14:10] = x_disp[14:10];
  assign LED[9:5]   = x_disp[9:5];
  assign LED[4:0]   = x_disp[4:0];

endmodule



