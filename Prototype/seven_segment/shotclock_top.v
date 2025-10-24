`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2025 04:41:05 PM
// Design Name: 
// Module Name: sevenseg_mux
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shotclock_top(
  input  wire clk_100MHz,
  input  wire btn_start,
  input  wire btn_reset,
  output wire [3:0] an,
  output wire [6:0] seg,
  output wire dp
);
  // TODO: hook real debouncers; for now, pass raw buttons
  wire start_pulse = btn_start;  // placeholder
  wire reset_sync  = btn_reset;  // placeholder

  // TODO: real clock divider; stub outputs held low
  wire tick_1hz;   // countdown tick (stub)
  wire scan_en;    // 7-seg scan enable (stub)
  clock_divider u_div(
    .clk(clk_100MHz),
    .rst(reset_sync),
    .tick_1hz(tick_1hz),
    .scan_en(scan_en)
  );

  // Shot clock digits (seconds only: S1 S0). Start at 24 by convention.
  // TODO: implement downcounter; for now just hardcode 2 and 4 to show wiring.
  wire [3:0] d3 = 4'hF; // blank
  wire [3:0] d2 = 4'hF; // blank
  wire [3:0] d1 = 4'd2; // tens
  wire [3:0] d0 = 4'd4; // ones

  // TODO: blink DP when running; for now keep off
  wire dp3 = 1'b1, dp2 = 1'b1, dp1 = 1'b1, dp0 = 1'b1;

  sevenseg_mux u_mux(
    .clk(clk_100MHz),
    .rst(reset_sync),
    .scan_en(scan_en),
    .d3(d3), .d2(d2), .d1(d1), .d0(d0),
    .dp3(dp3), .dp2(dp2), .dp1(dp1), .dp0(dp0),
    .an(an), .seg(seg), .dp(dp)
  );

endmodule