`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2025 04:41:05 PM
// Design Name: 
// Module Name: debounce
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


module debounce(
  input  wire clk,
  input  wire btn,
  output reg  pulse
);
  reg sync0 = 0, sync1 = 0;
  reg stable = 0, prev_stable = 0;
  reg [17:0] cnt = 0;  // ~2ms at 100MHz

  always @(posedge clk) begin
    sync0 <= btn;
    sync1 <= sync0;
  end

  always @(posedge clk) begin
    if (sync1 != stable)
      cnt <= 0;
    else if (cnt < 200_000)
      cnt <= cnt + 1;
    else
      stable <= sync1;
  end

  always @(posedge clk) begin
    prev_stable <= stable;
    pulse <= (stable & ~prev_stable); // 1-cycle rising edge
  end
endmodule