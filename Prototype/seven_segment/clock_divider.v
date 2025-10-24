`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2025 04:41:05 PM
// Design Name: 
// Module Name: clock_divider
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


module clock_divider(
  input  wire clk,
  input  wire rst,
  output reg  tick_1hz,
  output reg  scan_en
);
  // TODO: implement real counters. For now, keep low.
  always @(posedge clk) begin
    if (rst) begin
      tick_1hz <= 1'b0;
      scan_en  <= 1'b0;
    end else begin
      tick_1hz <= 1'b0; // placeholder pulse
      scan_en  <= 1'b0; // placeholder pulse
    end
  end
endmodule

