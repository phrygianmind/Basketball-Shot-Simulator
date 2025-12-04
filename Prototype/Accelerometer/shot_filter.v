`timescale 1ns/1ps
// shot_filter.v - show spikes from X only
// Author(s): Benjamin T
// x raw positional data is filtered to show "applied force", mimics shot flick motion

module shot_filter #(
  parameter ALPHA_SHIFT = 3   // bigger constant = slower baseline 
) (
  input  wire               clk,
  input  wire               rst,
  input  wire               x_valid,          // strobe from spi_master
  input  wire       [15:0]  x_raw,            // X is 12-bit signed
  output reg        [15:0]  flick = 16'd0     // spike magnitude for LCD
);
  // sign-extend 12-bit two's complement from x_raw[11:0]
  wire signed [15:0] x = { {4{x_raw[11]}}, x_raw[11:0] };

  reg  signed [15:0] baseline = 16'sd0;       // slow tilt estimate
  wire signed [15:0] err      = x - baseline; // high-passed signal

  wire [15:0] abs_err = err[15] ? (~err + 16'd1) : err;

  always @(posedge clk) begin
    if (rst) begin
      baseline <= 0;
      flick    <= 0;
    end else if (x_valid) begin
      // exponential moving average baseline
      baseline <= baseline + ((x - baseline) >>> ALPHA_SHIFT);
      // show absolute spike magnitude
      flick    <= abs_err;
    end
  end
endmodule
