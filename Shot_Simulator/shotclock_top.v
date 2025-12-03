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
  input  wire       CLK100MHZ,   // 100 MHz system clock
  input  wire       BTNC,        // start/load countdown
  input  wire       BTNR,        // reset button
  output wire [7:0] an,          // anode controls
  output wire [6:0] seg,         // segment outputs
  output wire zero               // detect timer is 0
);

  wire start_db;
  wire rst_db;

  btn_sync u_start_db (
    .clk    (CLK100MHZ),
    .btn_in (BTNC),
    .btn_db (start_db)
  );

  btn_sync u_rst_db (
    .clk    (CLK100MHZ),
    .btn_in (BTNR),
    .btn_db (rst_db)
  );

  wire rst = rst_db;

  wire tick_1hz;
  wire scan_en;

  sevenseg_clock_divider div (
    .clk      (CLK100MHZ),
    .rst      (rst),
    .tick_1hz (tick_1hz),
    .scan_en  (scan_en)
  );

  wire [3:0] s1, s0;
  wire       zero_int;

  bcd_counter counter (
    .clk      (CLK100MHZ),
    .rst      (rst),
    .load     (start_db),
    .tick_1hz (tick_1hz),
    .s1       (s1),
    .s0       (s0),
    .zero     (zero_int)
  );
    
   assign zero = zero_int;

  sevenseg_mux display (
    .clk     (CLK100MHZ),
    .rst     (rst),
    .scan_en (scan_en),
    .d3      (4'hF),
    .d2      (4'hF),
    .d1      (s1),
    .d0      (s0),
    .an      (an),
    .seg     (seg)
  );

endmodule
