`timescale 1ns/1ps
// seg7_xraw - display signed 12-bit X value on 4 leftmost digits.
// Author(s): Benjamin T, Toby P, Kevin L
// for debugging accelerometer only, not to be implemented in final product
// DP acts as a minus indicator on the ones digit.

module seg7_xraw(
    input  wire        CLK100MHZ,
    input  wire [15:0] x_raw,      // use bits [11:0] as signed value
    output reg  [6:0]  seg,
    output reg         dp,
    output reg  [7:0]  an
);

  // ===== scan timing (~1 ms per digit) =====
  reg [2:0]  anode_select = 3'd0;
  reg [16:0] anode_timer  = 17'd0;
  always @(posedge CLK100MHZ) begin
    if (anode_timer == 17'd99_999) begin
      anode_timer  <= 0;
      anode_select <= anode_select + 3'd1;
    end else begin
      anode_timer  <= anode_timer + 17'd1;
    end
  end

  // anode decode (active-low)
  always @(*) begin
    case (anode_select)
      3'b000: an = 8'b1111_1110;
      3'b001: an = 8'b1111_1101;
      3'b010: an = 8'b1111_1011;
      3'b011: an = 8'b1111_0111;
      3'b100: an = 8'b1110_1111; // ones
      3'b101: an = 8'b1101_1111; // tens
      3'b110: an = 8'b1011_1111; // hundreds
      3'b111: an = 8'b0111_1111; // thousands (leftmost)
      default: an = 8'b1111_1111;
    endcase
  end

  // 7-seg encoding
  localparam [6:0] ZERO=7'b000_0001, ONE=7'b100_1111, TWO=7'b001_0010, THREE=7'b000_0110,
                   FOUR=7'b100_1100, FIVE=7'b010_0100, SIX=7'b010_0000, SEVEN=7'b000_1111,
                   EIGHT=7'b000_0000, NINE=7'b000_0100, NULL=7'b111_1111;

  function [6:0] digit7;
    input [3:0] d;
    case (d)
      4'd0: digit7 = ZERO;  4'd1: digit7 = ONE;   4'd2: digit7 = TWO;   4'd3: digit7 = THREE;
      4'd4: digit7 = FOUR;  4'd5: digit7 = FIVE;  4'd6: digit7 = SIX;   4'd7: digit7 = SEVEN;
      4'd8: digit7 = EIGHT; 4'd9: digit7 = NINE;  default: digit7 = NULL;
    endcase
  endfunction

  // signed 12-bit value and magnitude
  wire signed [11:0] x12 = x_raw[11:0];
  wire neg = x12[11];
  wire [11:0] mag = neg ? (~x12 + 12'd1) : x12;  // 0..2047

  // decimal digits
  reg [3:0] d_th, d_hu, d_te, d_on;  // thousands, hundreds, tens, ones
  integer v;                         // <- moved here (module scope)

  always @* begin
    v    = mag;            // 0..2047
    d_th = v / 1000; v = v % 1000;
    d_hu = v / 100;  v = v % 100;
    d_te = v / 10;
    d_on = v % 10;
  end

  // leading-zero blanking
  wire blank_th = (d_th == 0);
  wire blank_hu = blank_th && (d_hu == 0);
  wire blank_te = blank_hu && (d_te == 0);

  // active digit drive
  always @* begin
    dp  = 1'b1;
    seg = NULL;
    case (anode_select)
      3'b111: seg = blank_th ? NULL : digit7(d_th);
      3'b110: seg = blank_hu ? NULL : digit7(d_hu);
      3'b101: seg = blank_te ? NULL : digit7(d_te);
      3'b100: begin
                seg = digit7(d_on);
                dp  = neg ? 1'b0 : 1'b1;   // DP lit = negative
              end
      default: seg = NULL;
    endcase
  end
endmodule
