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


module bcd_downcounter #(
  parameter START_SS = 24
)(
  input  wire clk,
  input  wire rst,
  input  wire load,   // load START_SS
  input  wire tick,   // 1 Hz
  input  wire hold,   // stop
  output reg  [3:0] s1, // tens
  output reg  [3:0] s0, // ones
  output wire zero
);
  assign zero = (s1 == 0 && s0 == 0);

  // TODO: on reset/load, set s1/s0 to START_SS; on tick, decrement BCD.
  always @(posedge clk) begin
    if (rst || load) begin
      s1 <= START_SS/10;
      s0 <= START_SS%10;
    end else if (tick && !hold && !zero) begin
      // TODO: implement BCD borrow logic
      s1 <= s1;
      s0 <= s0;
    end
  end
endmodule

