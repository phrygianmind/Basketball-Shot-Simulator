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

  reg sel = 0;  // 1-bit toggle for 2 digits
  reg [3:0] nib;

  // Decimal point not used; signal removed.

  function [6:0] enc;
    input [3:0] v;
    begin
      // seg[6:0] = g f e d c b a (XDC mapping), active-low (0 = ON)
      case (v)
        4'd0: enc = 7'b1000000;  // 0: segments a,b,c,d,e,f ON
        4'd1: enc = 7'b1111001;  // 1: segments b,c ON
        4'd2: enc = 7'b0100100;  // 2: segments a,b,d,e,g ON
        4'd3: enc = 7'b0110000;  // 3: segments a,b,c,d,g ON
        4'd4: enc = 7'b0011001;  // 4: segments b,c,f,g ON
        4'd5: enc = 7'b0010010;  // 5: segments a,c,d,f,g ON
        4'd6: enc = 7'b0000010;  // 6: segments a,c,d,e,f,g ON
        4'd7: enc = 7'b1111000;  // 7: segments a,b,c ON
        4'd8: enc = 7'b0000000;  // 8: all segments ON
        4'd9: enc = 7'b0010000;  // 9: segments a,b,c,d,f,g ON
        default: enc = 7'b1111111; // blank: all OFF
      endcase
    end
  endfunction 

assign seg = enc(nib);

  always @(posedge clk) begin
    if (rst)
      sel <= 0;
    else if (scan_en)
      sel <= ~sel;  // toggle between 0 and 1
  end

  always @* begin
    if (sel == 0) begin
      an = 4'b1110;  // enable digit 0 (ones)
      nib = d0;
    end else begin
      an = 4'b1101;  // enable digit 1 (tens)
      nib = d1;
    end
  end

endmodule