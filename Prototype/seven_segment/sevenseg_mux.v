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
  input  wire scan_en,              // ~4 kHz scan pulse
  input  wire [3:0] d3, d2, d1, d0, // digit data
  input  wire dp3, dp2, dp1, dp0,   // decimal points
  output reg  [3:0] an,             // digit enables (active-low)
  output wire [6:0] seg,            // segment lines (active-low)
  output reg  dp                    // decimal point (active-low)
);

  reg [1:0] sel = 0;
  reg [3:0] nib;

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
        default: enc = 7'b1111111;
      endcase
    end
  endfunction

  assign seg = enc(nib);

  always @(posedge clk) begin
    if (rst)
      sel <= 0;
    else if (scan_en)
      sel <= sel + 1;
  end

  always @* begin
    an = 4'b1111;
    dp = 1'b1;
    nib = 4'hF;

    case (sel)
      2'd0: begin an = 4'b1110; nib = d0; dp = ~dp0; end
      2'd1: begin an = 4'b1101; nib = d1; dp = ~dp1; end
      2'd2: begin an = 4'b1011; nib = d2; dp = ~dp2; end
      2'd3: begin an = 4'b0111; nib = d3; dp = ~dp3; end
    endcase
  end
endmodule