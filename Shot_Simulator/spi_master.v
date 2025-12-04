`timescale 1ns/1ps
// spi_master - ADXL362 X and Y only reader 
// Author(s): Benjamin T, Toby P, Kevin L
// - Power-up wait
// - WRITE: 0x0A, addr 0x2D (POWER_CTL), data 0x02 (Measurement)
// - Loop:  READ: 0x0B from 0x0E (X_L), then X_L, X_H, Y_L, Y_H
// - Outputs: x_raw/y_raw with 1-cycle valid strobes
// refactored with help of ChatGPT-5.1
module spi_master(
    input  wire        iclk,
    input  wire        miso,
    output wire        sclk,
    output reg         mosi  = 1'b0,
    output reg         cs    = 1'b1,
    output wire [14:0] acl_data,
    output reg  [15:0] x_raw   = 16'd0,
    output reg         x_valid = 1'b0,
    output reg  [15:0] y_raw   = 16'd0,
    output reg         y_valid = 1'b0
);

  // SCLK divider and edge detect 
  reg sclk_en     = 1'b0;   // gated out to the pin
  reg div2        = 1'b0;
  reg sclk_core   = 1'b0;

  always @(posedge iclk) begin
    if (!sclk_en) begin
      // Force idle-low and reset divider/phase while disabled
      div2      <= 1'b0;
      sclk_core <= 1'b0;
    end else begin
      div2 <= ~div2;
      if (div2) sclk_core <= ~sclk_core; // iclk/4
    end
  end

  assign sclk = sclk_en ? sclk_core : 1'b0;

  // edge detect from gated SCLK pin
  reg sclk_d = 1'b0;
  always @(posedge iclk) sclk_d <= sclk;
  wire sclk_rise = (sclk_d==1'b0) && (sclk==1'b1);
  wire sclk_fall = (sclk_d==1'b1) && (sclk==1'b0);

  // ADXL362 constants
  localparam [7:0] CMD_WRITE  = 8'h0A;
  localparam [7:0] CMD_READ   = 8'h0B;
  localparam [7:0] REG_PWRCTL = 8'h2D;
  localparam [7:0] MEASURE    = 8'h02;
  localparam [7:0] REG_X_L    = 8'h0E;

  // byte shifter (MSB first)
  reg [7:0] tx_sh  = 8'h00;
  reg [7:0] rx_sh  = 8'h00;
  reg [2:0] bit_ix = 3'd7;

  reg       tx_load = 1'b0;
  reg [7:0] tx_data = 8'h00;

  reg byte_done_r = 1'b0;  // pulses when we sample the 8th bit
  reg byte_done_q = 1'b0;  // 1-cycle delayed for FSM

  always @(posedge iclk) begin
    // defaults
    byte_done_r <= 1'b0;

    // drive MOSI on the falling half (mode-0)
    if (sclk_en && sclk_fall)
      mosi <= tx_sh[7];

    // load new TX or shift/sample
    if (tx_load) begin
      tx_sh  <= tx_data;
      bit_ix <= 3'd7;
    end else if (sclk_en && sclk_rise) begin
      rx_sh <= {rx_sh[6:0], miso};         // sample MISO
      tx_sh <= {tx_sh[6:0], 1'b0};         // shift out (next bit ready on next fall)

      if (bit_ix == 3'd0) begin
        byte_done_r <= 1'b1;               // just captured last bit of this byte
        // keep bit_ix at 0; will be reloaded by tx_load
      end else begin
        bit_ix <= bit_ix - 3'd1;
      end
    end

    // align the done pulse for the FSM (visible next iclk)
    byte_done_q <= byte_done_r;
  end

  // timing gaps
  localparam integer PWRUP_TICKS = 24000; // ~6 ms @ 4 MHz 
  localparam integer IFG_TICKS   = 40000; // ~10 ms @ 4 MHz
  reg [31:0] waitcnt = 32'd0;


  reg [7:0] xl=8'h00, xh=8'h00;
  reg [7:0] yl=8'h00, yh=8'h00;

  assign acl_data = {x_raw[11:7], y_raw[11:7], 5'b0};

  // FSM
  localparam [4:0]
    ST_PWRUP   = 5'd0,
    ST_W_CMD   = 5'd1,
    ST_W_ADDR  = 5'd2,
    ST_W_DATA  = 5'd3,
    ST_W_END   = 5'd4,
    ST_IFG1    = 5'd5,
    ST_R_CMD   = 5'd6,
    ST_R_ADDR  = 5'd7,
    ST_RX_XL   = 5'd8,
    ST_RX_XH   = 5'd9,
    ST_RX_YL   = 5'd10,
    ST_RX_YH   = 5'd11,
    ST_R_END   = 5'd12,
    ST_IFG2    = 5'd13;

  reg [4:0] state = ST_PWRUP;

  always @(posedge iclk) begin
    // defaults
    x_valid <= 1'b0;
    y_valid <= 1'b0;
    tx_load <= 1'b0;

    case (state)
      ST_PWRUP: begin
        cs <= 1'b1; sclk_en <= 1'b0;
        if (waitcnt >= PWRUP_TICKS) begin
          waitcnt <= 0;
          cs <= 1'b0; sclk_en <= 1'b1;
          tx_data <= CMD_WRITE; tx_load <= 1'b1;
          state   <= ST_W_CMD;
        end else begin
          waitcnt <= waitcnt + 1;
        end
      end

      // write 0x02 to POWER_CTL 
      ST_W_CMD:  if (byte_done_q) begin tx_data<=REG_PWRCTL; tx_load<=1'b1; state<=ST_W_ADDR; end
      ST_W_ADDR: if (byte_done_q) begin tx_data<=MEASURE;    tx_load<=1'b1; state<=ST_W_DATA; end
      ST_W_DATA: if (byte_done_q) begin cs<=1'b1; state<=ST_W_END; end
      ST_W_END:  state <= ST_IFG1;

      // inter-fram gap before 1st read 
      ST_IFG1: begin
        sclk_en <= 1'b0; cs <= 1'b1;
        if (waitcnt >= IFG_TICKS) begin
          waitcnt <= 0;
          cs <= 1'b0; sclk_en <= 1'b1;
          tx_data <= CMD_READ; tx_load <= 1'b1;
          state   <= ST_R_CMD;
        end else begin
          waitcnt <= waitcnt + 1;
        end
      end

      // read burst
      ST_R_CMD:  if (byte_done_q) begin tx_data<=REG_X_L; tx_load<=1'b1; state<=ST_R_ADDR; end

      // load first dummy immediately when ADDR completes
      ST_R_ADDR: if (byte_done_q) begin
        tx_data <= 8'h00; tx_load <= 1'b1;  // First dummy to clock X_L
        state   <= ST_RX_XL;
      end

      // X_L
      ST_RX_XL: if (byte_done_q) begin
        xl      <= rx_sh;
        tx_data <= 8'h00; tx_load <= 1'b1; // dummy to clock X_H
        state   <= ST_RX_XH;
      end

      // X_H
      ST_RX_XH: if (byte_done_q) begin
        xh      <= rx_sh;
        x_raw   <= {rx_sh, xl};
        x_valid <= 1'b1;

        tx_data <= 8'h00; tx_load <= 1'b1; // dummy to clock Y_L
        state   <= ST_RX_YL;
      end

      // Y_L
      ST_RX_YL: if (byte_done_q) begin
        yl      <= rx_sh;
        tx_data <= 8'h00; tx_load <= 1'b1; // dummy to clock Y_H
        state   <= ST_RX_YH;
      end

      // Y_H
      ST_RX_YH: if (byte_done_q) begin
        yh      <= rx_sh;
        y_raw   <= {rx_sh, yl};
        y_valid <= 1'b1;

        cs      <= 1'b1;                   // end transaction
        state   <= ST_R_END;
      end

      ST_R_END:  state <= ST_IFG2;

      // inter-frame gap, then repeat
      ST_IFG2: begin
        sclk_en <= 1'b0; cs <= 1'b1;
        if (waitcnt >= IFG_TICKS) begin
          waitcnt <= 0;
          cs <= 1'b0; sclk_en <= 1'b1;
          tx_data <= CMD_READ; tx_load <= 1'b1;
          state   <= ST_R_CMD;
        end else begin
          waitcnt <= waitcnt + 1;
        end
      end

      default: state <= ST_PWRUP;
    endcase
  end

endmodule
