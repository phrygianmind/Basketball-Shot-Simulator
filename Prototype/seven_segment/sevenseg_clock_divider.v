`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2025 04:41:05 PM
// Design Name: 
// Module Name: sevenseg_clock_divider
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


module sevenseg_clock_divider(
  input  wire clk,
  input  wire rst,
  output reg  tick_1hz,
  output reg  scan_en
);

  // Constants for 100 MHz clock
  localparam integer TICK_MAX = 100_000_000 - 1;   // 1 Hz
  localparam integer SCAN_MAX = 25_000 - 1;        // 4 kHz

  reg [31:0] tick_cnt = 0;
  reg [15:0] scan_cnt = 0;

  always @(posedge clk) begin
    if (rst) begin
      tick_cnt <= 0;
      tick_1hz <= 0;
    end else begin
      tick_1hz <= 0;
      if (tick_cnt == TICK_MAX) begin
        tick_cnt <= 0;
        tick_1hz <= 1;
      end else begin
        tick_cnt <= tick_cnt + 1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      scan_cnt <= 0;
      scan_en <= 0;
    end else begin
      scan_en <= 0;
      if (scan_cnt == SCAN_MAX) begin
        scan_cnt <= 0;
        scan_en <= 1;
      end else begin
        scan_cnt <= scan_cnt + 1;
      end
    end
  end
endmodule
