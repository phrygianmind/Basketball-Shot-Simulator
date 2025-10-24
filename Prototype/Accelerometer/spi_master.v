`timescale 1ns/1ps
// spi_master - ADXL362 X-only reader
// - Power-up wait
// - WRITE: 0x0A, addr 0x2D (POWER_CTL), data 0x02 (Measurement)
// - Loop:  READ: 0x0B from 0x0E (X_L), capture X_L, X_H (2 bytes)
// - Exposes: x_raw[15:0], x_valid (strobe), and legacy acl_data = {X[11:7], 5'b0, 5'b0}
// refactored with help of ChatGPT 5
module spi_master(
    input  wire        iclk,        // 4 MHz input clock
    input  wire        miso,        // MISO from ADXL362
    output wire        sclk,        // SPI clock (~1 MHz when active)
    output reg         mosi  = 1'b0,// MOSI to ADXL362
    output reg         cs    = 1'b1,// chip select (active low)

    // legacy packed output kept for compatibility: now X-only
    output wire [14:0] acl_data,

    // explicit X outputs (optional to use upstream)
    output reg  [15:0] x_raw   = 16'd0, // {X_H, X_L}
    output reg         x_valid = 1'b0   // 1-cycle pulse when x_raw updates
);

    // 1 MHz SCLK from 4 MHz iclk, gated by sclk_en (mode-0)
    reg sclk_en     = 1'b0;
    reg div2        = 1'b0; // divide-by-2 of 4 MHz -> 2 MHz toggle
    reg sclk_core   = 1'b0; // 1 MHz when enabled
    reg sclk_core_d = 1'b0;

    always @(posedge iclk) begin
        div2 <= ~div2;
        if (div2) sclk_core <= ~sclk_core; // toggle every other iclk -> 1 MHz
        sclk_core_d <= sclk_core;
    end

    assign sclk = sclk_en ? sclk_core : 1'b0;

    wire sclk_rise = sclk_en && (sclk_core_d == 1'b0) && (sclk_core == 1'b1);
    wire sclk_fall = sclk_en && (sclk_core_d == 1'b1) && (sclk_core == 1'b0);

    // ADXL362 opcodes/addresses
    localparam [7:0] CMD_WRITE  = 8'h0A;
    localparam [7:0] CMD_READ   = 8'h0B;
    localparam [7:0] REG_PWRCTL = 8'h2D;
    localparam [7:0] MEASURE    = 8'h02;
    localparam [7:0] REG_X_L    = 8'h0E; // start of X low byte

    // Byte shifter (MSB-first, mode-0)
    reg [7:0] tx_sh  = 8'h00;
    reg [7:0] rx_sh  = 8'h00;
    reg [2:0] bit_ix = 3'd7;

    // update MOSI on falling; sample MISO on rising (mode-0)
    always @(posedge iclk) begin
        if (sclk_en && sclk_fall)
            mosi <= tx_sh[7];                 // present next MSB before rising edge
        if (sclk_en && sclk_rise) begin
            rx_sh  <= {rx_sh[6:0], miso};     // sample on rising edge
            tx_sh  <= {tx_sh[6:0], 1'b0};     // shift out after sample
            if (bit_ix != 0) bit_ix <= bit_ix - 1'b1;
        end
    end

    wire byte_done = sclk_en && sclk_rise && (bit_ix == 3'd0);

    task start_tx;
      input [7:0] b;
      begin
        tx_sh  <= b;
        bit_ix <= 3'd7;
        // MOSI will reflect MSB on next sclk_fall
      end
    endtask

    // FSM: init (3 bytes) -> loop read X (2 bytes)
    // State encodings 
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

    // power-up (~6 ms @ 4 MHz) + inter-frame (~10 ms)
    localparam integer PWRUP_TICKS = 24000; // 4e6 * 6e-3
    localparam integer IFG_TICKS   = 40000; // 4e6 * 10e-3
    reg [31:0] waitcnt = 32'd0;

    // X latches
    reg [7:0] xl = 8'h00, xh = 8'h00;

    
    assign acl_data = {x_raw[11:7], 5'b0, 5'b0};

    always @(posedge iclk) begin
        x_valid <= 1'b0; // default

        case (state)
            // Power-up wait 
            ST_PWRUP: begin
                cs <= 1'b1; sclk_en <= 1'b0;
                if (waitcnt >= PWRUP_TICKS) begin
                    waitcnt <= 0;
                    cs <= 1'b0; sclk_en <= 1'b1;
                    start_tx(CMD_WRITE);      // 0x0A
                    state <= ST_W_CMD;
                end else begin
                    waitcnt <= waitcnt + 1;
                end
            end

            // init write: 0x0A, 0x2D, 0x02 
            ST_W_CMD:  if (byte_done) begin sclk_en <= 1'b0; start_tx(REG_PWRCTL); sclk_en <= 1'b1; state <= ST_W_ADDR; end
            ST_W_ADDR: if (byte_done) begin sclk_en <= 1'b0; start_tx(MEASURE);    sclk_en <= 1'b1; state <= ST_W_DATA; end
            ST_W_DATA: if (byte_done) begin sclk_en <= 1'b0; cs <= 1'b1;           state <= ST_W_END; end
            ST_W_END:  begin state <= ST_IFG1; end

            // idle before first read 
            ST_IFG1: begin
                sclk_en <= 1'b0; cs <= 1'b1;
                if (waitcnt >= IFG_TICKS) begin
                    waitcnt <= 0;
                    cs <= 1'b0; sclk_en <= 1'b1;
                    start_tx(CMD_READ);       // 0x0B
                    state <= ST_R_CMD;
                end else begin
                    waitcnt <= waitcnt + 1;
                end
            end

            // read x only: 0x0B, 0x0E, then 2 bytes
            ST_R_CMD:  if (byte_done) begin sclk_en <= 1'b0; start_tx(REG_X_L); sclk_en <= 1'b1; state <= ST_R_ADDR; end
            ST_R_ADDR: if (byte_done) begin sclk_en <= 1'b0; start_tx(8'h00);   sclk_en <= 1'b1; state <= ST_RX_XL;  end

            ST_RX_XL: if (byte_done) begin
                sclk_en <= 1'b0; xl <= rx_sh;
                start_tx(8'h00); sclk_en <= 1'b1; state <= ST_RX_XH;
            end

            ST_RX_XH: if (byte_done) begin
                sclk_en <= 1'b0; xh <= rx_sh;
                cs <= 1'b1; state <= ST_R_END;
                x_raw   <= {xh, xl};
                x_valid <= 1'b1;              // new X sample
            end

            ST_R_END: begin
                state <= ST_IFG2;
            end

            // inter-frame gap: gives time between frames
            // increased polling accuracy
            ST_IFG2: begin
                sclk_en <= 1'b0; cs <= 1'b1;
                if (waitcnt >= IFG_TICKS) begin
                    waitcnt <= 0;
                    cs <= 1'b0; sclk_en <= 1'b1;
                    start_tx(CMD_READ);
                    state <= ST_R_CMD;
                end else begin
                    waitcnt <= waitcnt + 1;
                end
            end

            default: state <= ST_PWRUP;
        endcase
    end

endmodule
