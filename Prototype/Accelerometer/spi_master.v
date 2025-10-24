`timescale 1ns/1ps
// spi_master - ADXL362 X-only reader
// Author(s): Benjamin T, Toby P, Kevin L
// - Power-up wait
// - WRITE: 0x0A, addr 0x2D (POWER_CTL), data 0x02 (Measurement)
// - Loop:  READ: 0x0B from 0x0E (X_L), capture X_L, X_H (2 bytes)
// - Exposes: x_raw[15:0], x_valid (strobe), and legacy acl_data = {X[11:7], 5'b0, 5'b0}
// refactored with help of ChatGPT 5
module spi_master(
    input  wire        iclk,
    input  wire        miso,
    output wire        sclk,
    output reg         mosi  = 1'b0,
    output reg         cs    = 1'b1,
    output wire [14:0] acl_data,
    output reg  [15:0] x_raw   = 16'd0,
    output reg         x_valid = 1'b0
);
  //  Clock divide/gate (mode-0) 
  reg sclk_en     = 1'b0;
  reg div2        = 1'b0;
  reg sclk_core   = 1'b0;
  reg sclk_core_d = 1'b0;
  always @(posedge iclk) begin
    div2 <= ~div2;
    if (div2) sclk_core <= ~sclk_core; // 1 MHz from 4 MHz iclk
    sclk_core_d <= sclk_core;
  end
  assign sclk = sclk_en ? sclk_core : 1'b0;
  wire sclk_rise = sclk_en && (sclk_core_d==1'b0) && (sclk_core==1'b1);
  wire sclk_fall = sclk_en && (sclk_core_d==1'b1) && (sclk_core==1'b0);

  // ADXL362 constants 
  localparam [7:0] CMD_WRITE  = 8'h0A;
  localparam [7:0] CMD_READ   = 8'h0B;
  localparam [7:0] REG_PWRCTL = 8'h2D;
  localparam [7:0] MEASURE    = 8'h02;
  localparam [7:0] REG_X_L    = 8'h0E;

  //  Byte shifter (single writer) 
  reg [7:0] tx_sh  = 8'h00;
  reg [7:0] rx_sh  = 8'h00;
  reg [2:0] bit_ix = 3'd7;

  // handshake from FSM:
  reg        tx_load = 1'b0;   // assert for 1 iclk to load a new byte
  reg [7:0]  tx_data = 8'h00;  // byte to load when tx_load=1

  // Drive MOSI on falling half; sample MISO on rising; handle loads here only
  always @(posedge iclk) begin
    if (sclk_en && sclk_fall)
      mosi <= tx_sh[7];

    if (tx_load) begin
      tx_sh  <= tx_data;
      bit_ix <= 3'd7;
    end else if (sclk_en && sclk_rise) begin
      rx_sh  <= {rx_sh[6:0], miso};
      tx_sh  <= {tx_sh[6:0], 1'b0};
      if (bit_ix != 0) bit_ix <= bit_ix - 1'b1;
    end
  end

  wire byte_done = sclk_en && sclk_rise && (bit_ix == 3'd0);

  // Timing gaps
  localparam integer PWRUP_TICKS = 24000; // ~6 ms @ 4 MHz
  localparam integer IFG_TICKS   = 40000; // ~10 ms @ 4 MHz
  reg [31:0] waitcnt = 32'd0;

  // X latches + packed output
  reg [7:0] xl = 8'h00, xh = 8'h00;
  assign acl_data = {x_raw[11:7], 5'b0, 5'b0};

  //  FSM 
  localparam [3:0]
    ST_PWRUP  = 4'd0,
    ST_W_CMD  = 4'd1,
    ST_W_ADDR = 4'd2,
    ST_W_DATA = 4'd3,
    ST_W_END  = 4'd4,
    ST_IFG1   = 4'd5,
    ST_R_CMD  = 4'd6,
    ST_R_ADDR = 4'd7,
    ST_RX_XL  = 4'd8,
    ST_RX_XH  = 4'd9,
    ST_R_END  = 4'd10,
    ST_IFG2   = 4'd11;

  reg [3:0] state = ST_PWRUP;

  always @(posedge iclk) begin
    // defaults every cycle
    x_valid <= 1'b0;
    tx_load <= 1'b0;

    case (state)
      ST_PWRUP: begin
        cs <= 1'b1; sclk_en <= 1'b0;
        if (waitcnt >= PWRUP_TICKS) begin
          waitcnt <= 0;
          cs <= 1'b0; sclk_en <= 1'b1;
          tx_data <= CMD_WRITE; tx_load <= 1'b1;  // load 0x0A
          state <= ST_W_CMD;
        end else begin
          waitcnt <= waitcnt + 1;
        end
      end

      // Write: 0x0A, 0x2D, 0x02
      ST_W_CMD:  if (byte_done) begin sclk_en<=1'b0; tx_data<=REG_PWRCTL; tx_load<=1'b1; sclk_en<=1'b1; state<=ST_W_ADDR; end
      ST_W_ADDR: if (byte_done) begin sclk_en<=1'b0; tx_data<=MEASURE;    tx_load<=1'b1; sclk_en<=1'b1; state<=ST_W_DATA; end
      ST_W_DATA: if (byte_done) begin sclk_en<=1'b0; cs<=1'b1; state<=ST_W_END; end
      ST_W_END:  state <= ST_IFG1;

      // Gap before first read
      ST_IFG1: begin
        sclk_en <= 1'b0; cs <= 1'b1;
        if (waitcnt >= IFG_TICKS) begin
          waitcnt <= 0;
          cs <= 1'b0; sclk_en <= 1'b1;
          tx_data <= CMD_READ; tx_load <= 1'b1;  // 0x0B
          state <= ST_R_CMD;
        end else begin
          waitcnt <= waitcnt + 1;
        end
      end

      // Read X only: 0x0B, 0x0E, then 2 data bytes
      ST_R_CMD:  if (byte_done) begin sclk_en<=1'b0; tx_data<=REG_X_L; tx_load<=1'b1; sclk_en<=1'b1; state<=ST_R_ADDR; end
      ST_R_ADDR: if (byte_done) begin sclk_en<=1'b0; tx_data<=8'h00;   tx_load<=1'b1; sclk_en<=1'b1; state<=ST_RX_XL;  end

      ST_RX_XL: if (byte_done) begin
        sclk_en<=1'b0; xl<=rx_sh;
        tx_data<=8'h00; tx_load<=1'b1; sclk_en<=1'b1; state<=ST_RX_XH;
      end

      ST_RX_XH: if (byte_done) begin
        sclk_en<=1'b0; xh<=rx_sh; cs<=1'b1; state<=ST_R_END;
        x_raw <= {xh, xl}; x_valid <= 1'b1;
      end

      ST_R_END:  state <= ST_IFG2;

      // Inter-frame gap, then repeat read
      ST_IFG2: begin
        sclk_en <= 1'b0; cs <= 1'b1;
        if (waitcnt >= IFG_TICKS) begin
          waitcnt <= 0;
          cs <= 1'b0; sclk_en <= 1'b1;
          tx_data <= CMD_READ; tx_load <= 1'b1;
          state <= ST_R_CMD;
        end else begin
          waitcnt <= waitcnt + 1;
        end
      end

      default: state <= ST_PWRUP;
    endcase
  end
endmodule
