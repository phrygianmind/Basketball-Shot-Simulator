`timescale 1ns/1ps
// shot_filter_xy.v - show spikes from X and Y (identical filter on both)
// Author(s): Benjamin T
// Each axis uses an EMA baseline and outputs abs(axis - baseline)
// x and y raw positional data are filtered to show "applied force", mimics shot flick motion


module shot_filter_xy #(
  parameter ALPHA_SHIFT = 3   // bigger constant = slower baseline
) (
  input  wire        clk,
  input  wire        rst,

  // X axis
  input  wire        x_valid,          // strobe from spi_master (for X sample)
  input  wire [15:0] x_raw,            // X is 12-bit signed in [11:0]
  output reg  [15:0] x_flick = 16'd0,  // spike magnitude for X

  // Y axis
  input  wire        y_valid,          // strobe from spi_master (for Y sample)
  input  wire [15:0] y_raw,            // Y is 12-bit signed in [11:0]
  output reg  [15:0] y_flick = 16'd0   // spike magnitude for Y
);

  // ----- X path -----
  wire signed [15:0] x = {{4{x_raw[11]}}, x_raw[11:0]};   // sign-extend 12b
  reg  signed [15:0] bx = 16'sd0;                         // X baseline
  wire signed [15:0] ex = x - bx;                         // high-pass
  wire [15:0] ax = ex[15] ? (~ex + 16'd1) : ex;           // |ex|

  // ----- Y path -----
  wire signed [15:0] y = {{4{y_raw[11]}}, y_raw[11:0]};   // sign-extend 12b
  reg  signed [15:0] by = 16'sd0;                         // Y baseline
  wire signed [15:0] ey = y - by;                         // high-pass
  wire [15:0] ay = ey[15] ? (~ey + 16'd1) : ey;           // |ey|

  always @(posedge clk) begin
    if (rst) begin
      bx <= 0; x_flick <= 0;
      by <= 0; y_flick <= 0;
    end else begin
      // Update X when its sample arrives
      if (x_valid) begin
        bx      <= bx + ((x - bx) >>> ALPHA_SHIFT);
        x_flick <= ax;
      end
      // Update Y when its sample arrives
      if (y_valid) begin
        by      <= by + ((y - by) >>> ALPHA_SHIFT);
        y_flick <= ay;
      end
    end
  end
endmodule
