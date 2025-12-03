`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2025 04:41:05 PM
// Design Name: 
// Module Name: bcd_counter
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


module bcd_counter(
  input  wire clk,
  input  wire rst,
  input  wire load,        // reload to 10
  input  wire tick_1hz,    // 1 Hz pulse
  output reg  [3:0] s1,    // tens
  output reg  [3:0] s0,    // ones
  output wire zero         // high when counter reaches 00
);

  assign zero = (s1 == 4'd0 && s0 == 4'd0);

  always @(posedge clk) begin
    if (rst || load) begin
      s1 <= 1;  // tens place of 10
      s0 <= 0;  // ones place of 10
    end 
    else if (tick_1hz && !zero) begin
      if (s0 == 0) begin
        s0 <= 9;
        if (s1 != 0) s1 <= s1 - 1;
      end 
      else begin
        s0 <= s0 - 1;
      end
    end
  end
endmodule