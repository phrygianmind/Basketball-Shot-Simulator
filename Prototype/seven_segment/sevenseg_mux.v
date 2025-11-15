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
  output reg  [3:0] an,             // digit enables (active-low)
  output wire [6:0] seg             // segment lines (active-low)
);

  reg [1:0] sel = 0;
  reg [3:0] nib;

  // Decimal point not used; signal removed.

  function [6:0] enc;
    input [3:0] v;
    begin
      // seg[6:0] = a b c d e f g, active-low (0 = ON)
      case (v)
        4'd0: enc = 7'b0000001;
        4'd1: enc = 7'b1001111;
        4'd2: enc = 7'b0010010;
        4'd3: enc = 7'b0000110;
        4'd4: enc = 7'b1001100;
        4'd5: enc = 7'b0100100;
        4'd6: enc = 7'b0100000;
        4'd7: enc = 7'b0001111;
        4'd8: enc = 7'b0000000;
        4'd9: enc = 7'b0000100;
        default: enc = 7'b1111111; // blank
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
    nib = 4'hF;
    an = 4'b1111;

    case (sel)
      2'd0: begin an = 4'b1110; nib = d0; end // ones digit
      2'd1: begin an = 4'b1101; nib = d1; end // tens digit
      default: an = 4'b1111; // others OFF
    endcase
  end

endmodule