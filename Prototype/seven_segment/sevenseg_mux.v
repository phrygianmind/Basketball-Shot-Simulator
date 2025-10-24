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


module sevenseg_mux(
  input  wire clk,
  input  wire rst,
  input  wire scan_en,
  input  wire [3:0] d3, d2, d1, d0,
  input  wire dp3, dp2, dp1, dp0,
  output reg  [3:0] an,
  output reg  [6:0] seg,
  output reg  dp
);
  reg [1:0] sel;
  reg [3:0] nib;

  // TODO: drive sel on scan_en; for now, freeze at digit 0
  always @(posedge clk) begin
    if (rst) sel <= 2'd0;
    else if (scan_en) sel <= sel + 2'd1; // will never tick until divider real
  end

  // Simple hex-to-7seg for 0-9 only (common anode patterns)
  function [6:0] enc;
    input [3:0] v;
    begin
      case (v)
        4'd0: enc = 7'b1000000;
        4'd1: enc = 7'b1111001;
        4'd2: enc = 7'b0100100;
        4'd3: enc = 7'b0110000;
        4'd4: enc = 7'b0011001;
        4'd5: enc = 7'b0010010;
        4'd6: enc = 7'b0000010;
        4'd7: enc = 7'b1111000;
        4'd8: enc = 7'b0000000;
        4'd9: enc = 7'b0010000;
        default: enc = 7'b1111111; // blank
      endcase
    end
  endfunction

  // One active digit at a time; placeholder chooses d0
  always @* begin
    an  = 4'b1110;     // enable digit0 only (active low on Nexys A7)
    seg = enc(d0);     // show ones digit
    dp  = 1'b1;        // decimal point off (common anode)
  end
endmodule
