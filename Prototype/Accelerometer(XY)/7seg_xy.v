`timescale 1ns/1ps
// seg7_xy - display signed 12-bit X and Y value on LCD.
// Author(s): Benjamin T, Toby P, Kevin L
// for debugging accelerometer only, not to be implemented in final product
// reads (X,Y), each value is 4-bits

module seg7_xy(
    input  wire        CLK100MHZ,
    input  wire [15:0] x_raw,
    input  wire [15:0] y_raw,
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

  // anode decode (active-low). AN0 is rightmost on Basys-3.
  always @(*) begin
    case (anode_select)
      3'b000: an = 8'b1111_1110; // Y ones   (rightmost)
      3'b001: an = 8'b1111_1101; // Y tens
      3'b010: an = 8'b1111_1011; // Y hundreds
      3'b011: an = 8'b1111_0111; // Y thousands
      3'b100: an = 8'b1110_1111; // X ones
      3'b101: an = 8'b1101_1111; // X tens
      3'b110: an = 8'b1011_1111; // X hundreds
      3'b111: an = 8'b0111_1111; // X thousands (leftmost)
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

  // signed 12-bit values and magnitudes
  wire signed [11:0] x12 = x_raw[11:0];
  wire signed [11:0] y12 = y_raw[11:0];
  wire neg_x = x12[11];
  wire neg_y = y12[11];
  wire [11:0] mag_x = neg_x ? (~x12 + 12'd1) : x12;  // 0..2047
  wire [11:0] mag_y = neg_y ? (~y12 + 12'd1) : y12;

  // decimal digits (X and Y)
  reg [3:0] x_th, x_hu, x_te, x_on;
  reg [3:0] y_th, y_hu, y_te, y_on;
  integer vx, vy;

  always @* begin
    // X
    vx   = mag_x;
    x_th = vx / 1000; vx = vx % 1000;
    x_hu = vx / 100;  vx = vx % 100;
    x_te = vx / 10;
    x_on = vx % 10;
    // Y
    vy   = mag_y;
    y_th = vy / 1000; vy = vy % 1000;
    y_hu = vy / 100;  vy = vy % 100;
    y_te = vy / 10;
    y_on = vy % 10;
  end

  // leading-zero blanking
  wire x_blank_th = (x_th == 0);
  wire x_blank_hu = x_blank_th && (x_hu == 0);
  wire x_blank_te = x_blank_hu && (x_te == 0);

  wire y_blank_th = (y_th == 0);
  wire y_blank_hu = y_blank_th && (y_hu == 0);
  wire y_blank_te = y_blank_hu && (y_te == 0);

  // active digit drive
  always @* begin
    dp  = 1'b1;
    seg = NULL;
    case (anode_select)
      // ---- Y on right 4 digits ----
      3'b011: seg = y_blank_th ? NULL : digit7(y_th);
      3'b010: seg = y_blank_hu ? NULL : digit7(y_hu);
      3'b001: seg = y_blank_te ? NULL : digit7(y_te);
      3'b000: begin
                seg = digit7(y_on);
                dp  = neg_y ? 1'b0 : 1'b1;   // DP lit = negative Y
              end
      // ---- X on left 4 digits ----
      3'b111: seg = x_blank_th ? NULL : digit7(x_th);
      3'b110: seg = x_blank_hu ? NULL : digit7(x_hu);
      3'b101: seg = x_blank_te ? NULL : digit7(x_te);
      3'b100: begin
                seg = digit7(x_on);
                dp  = neg_x ? 1'b0 : 1'b1;   // DP lit = negative X
              end
      default: seg = NULL;
    endcase
  end
endmodule
