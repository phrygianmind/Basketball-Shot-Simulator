`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2025 04:41:05 PM
// Design Name: 
// Module Name: shotclock_top
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
  input  wire CLK100MHZ,   // 100 MHz system clock
  input  wire BTNC,        // start/load countdown
  input  wire BTNR,        // reset button
  output wire [3:0] an,    // anode controls
  output wire [6:0] seg,   // segment outputs
  output wire dp           // decimal point
);

  wire start_pulse, reset_pulse;
  debounce db_start(.clk(CLK100MHZ), .btn(BTNC), .pulse(start_pulse));
  debounce db_reset(.clk(CLK100MHZ), .btn(BTNR), .pulse(reset_pulse));

  wire rst = reset_pulse;
  wire tick_1hz, scan_en;

  clock_divider div(
    .clk(CLK100MHZ),
    .rst(rst),
    .tick_1hz(tick_1hz),
    .scan_en(scan_en)
  );

  wire [3:0] s1, s0;
  wire zero;

  bcd_counter counter(
    .clk(CLK100MHZ),
    .rst(rst),
    .load(start_pulse),
    .tick_1hz(tick_1hz),
    .s1(s1),
    .s0(s0),
    .zero(zero)
  );

  /*
  sevenseg_mux display(
    .clk(CLK100MHZ),
    .rst(rst),
    .scan_en(scan_en),
    .d3(4'hF),
    .d2(4'hF),
    .d1(s1),
    .d0(s0),
    .dp3(1'b1),
    .dp2(1'b1),
    .dp1(1'b1),
    .dp0(1'b1),
    .an(an),
    .seg(seg),
    .dp(dp)
  );
  */

  assign dp  = 1'b1;         // decimal point OFF (active-low)
  assign an  = 4'b1110;      // enable only the right-most digit (active-low)
  assign seg = 7'b1000000;   // should display a “0” pattern
endmodule