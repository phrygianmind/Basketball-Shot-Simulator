`timescale 1ns/1ps
// spi_master_tb - self-checking with behavioral ADXL362 slave 
// Author(s): Benjamin Thai
// simulates spi communication with ADXL362 behavioral slave by using random X/Y data

module spi_master_tb;

  // clock
  reg iclk = 1'b0;
  localparam integer MAIN_CLK_PERIOD = 10; // 100 MHz
  always #(MAIN_CLK_PERIOD/2) iclk = ~iclk;

  // UUT I/O
  wire        sclk, mosi, cs;
  wire [14:0] acl_data;
  wire [15:0] x_raw, y_raw;
  wire        x_valid, y_valid;

  // MISO from slave model
  wire miso;

  // instantiate uut
  spi_master uut (
    .iclk    (iclk),
    .miso    (miso),
    .sclk    (sclk),
    .mosi    (mosi),
    .cs      (cs),
    .acl_data(acl_data),
    .x_raw   (x_raw),
    .x_valid (x_valid),
    .y_raw   (y_raw),
    .y_valid (y_valid)
  );

  // deterministic vectors
  localparam integer FRAMES = 16;
  reg [7:0] xL_vec [0:FRAMES-1];
  reg [7:0] xH_vec [0:FRAMES-1];
  reg [7:0] yL_vec [0:FRAMES-1];
  reg [7:0] yH_vec [0:FRAMES-1];

  integer vi, seed;
  initial begin
    seed = 32'h1234_5678;
    for (vi = 0; vi < FRAMES; vi = vi + 1) begin
      xL_vec[vi] = $random(seed);
      xH_vec[vi] = $random(seed);
      yL_vec[vi] = $random(seed);
      yH_vec[vi] = $random(seed);
    end
  end

  // behavioral SPI slave (mode-0)
  reg [7:0] sh_out = 8'h00;   // MSB at [7]
  assign miso = sh_out[7];

  // edge tracking
  reg sclk_d=0, cs_d=1;
  always @(posedge iclk) begin
    sclk_d <= sclk;
    cs_d   <= cs;
  end
  wire sclk_rise = (sclk_d==1'b0) && (sclk==1'b1);
  wire sclk_fall = (sclk_d==1'b1) && (sclk==1'b0);

  // command/address counting (rising edges)
  reg  [2:0] rise_ix    = 3'd0;  // 0..7 within a byte
  integer    bytes_seen = 0;     // 0,1,2 for cmd/addr bytes completed

  // streaming state (payload)
  reg        streaming  = 1'b0;
  reg  [1:0] data_ix    = 2'd0;  // 0:X_L, 1:X_H, 2:Y_L, 3:Y_H
  reg  [2:0] fall_ix    = 3'd7;  // 7..0 within a payload byte
  integer    vec_ix     = 0;     // frame index

  // arm flag - start streaming on the first sclk falling edge
  reg        arm_stream = 1'b0;

  function [7:0] cur_byte;
    input [1:0] ix;
    input integer vix;
    begin
      case (ix)
        2'd0: cur_byte = xL_vec[vix];
        2'd1: cur_byte = xH_vec[vix];
        2'd2: cur_byte = yL_vec[vix];
        default: cur_byte = yH_vec[vix];
      endcase
    end
  endfunction

  // count two bytes
  always @(posedge iclk) begin
    if (cs==1'b0) begin
      if (sclk_rise) begin
        if (rise_ix != 3'd7) begin
          rise_ix <= rise_ix + 3'd1;
        end else begin
          rise_ix <= 3'd0; // byte completed under CS low
          if (bytes_seen == 0) begin
            bytes_seen <= 1;       // first byte (READ) done
          end else if (bytes_seen == 1) begin
            // second byte (ADDR) done -> arm streaming; load on next falling
            bytes_seen <= 2;
            arm_stream <= 1'b1;
          end
        end
      end
    end else begin
      // new transaction
      rise_ix    <= 3'd0;
      bytes_seen <= 0;
      streaming  <= 1'b0;
      arm_stream <= 1'b0; // ensure we don't accidentally start on a stale arm
    end
  end

  // payload engine on falling edges
  always @(posedge iclk) begin
    if (cs==1'b0) begin
      if (sclk_fall) begin
        if (arm_stream) begin
          // 1st negedge after ADDR: present X_L[7] and start streaming
          arm_stream <= 1'b0;
          streaming  <= 1'b1;
          data_ix    <= 2'd0;
          fall_ix    <= 3'd7;
          sh_out     <= cur_byte(2'd0, vec_ix); // X_L MSB stable for next rising
        end else if (streaming) begin
          if (fall_ix != 3'd0) begin
            sh_out  <= {sh_out[6:0], 1'b0};
            fall_ix <= fall_ix - 3'd1;
          end else begin
            if (data_ix != 2'd3) begin
              data_ix <= data_ix + 2'd1;
              fall_ix <= 3'd7;
              sh_out  <= cur_byte(data_ix + 1, vec_ix); // next payload byte
            end else begin
              // finished Y_H; end of frame
              streaming <= 1'b0;
              vec_ix    <= (vec_ix + 1) % FRAMES;
            end
          end
        end
      end
    end
  end

  // self-checking 
  integer pass=0, fail=0, seen=0, expect_ix=0;

  always @(posedge iclk) begin
    if (x_valid) begin
      if (x_raw == {xH_vec[expect_ix], xL_vec[expect_ix]}) begin
        $display("X PASS vec=%0d exp=%h got=%h",
                 expect_ix, {xH_vec[expect_ix], xL_vec[expect_ix]}, x_raw);
        pass = pass + 1;
      end else begin
        $display("X FAIL vec=%0d exp=%h got=%h",
                 expect_ix, {xH_vec[expect_ix], xL_vec[expect_ix]}, x_raw);
        fail = fail + 1;
      end
    end
    if (y_valid) begin
      if (y_raw == {yH_vec[expect_ix], yL_vec[expect_ix]}) begin
        $display("Y PASS vec=%0d exp=%h got=%h",
                 expect_ix, {yH_vec[expect_ix], yL_vec[expect_ix]}, y_raw);
        pass = pass + 1;
      end else begin
        $display("Y FAIL vec=%0d exp=%h got=%h",
                 expect_ix, {yH_vec[expect_ix], yL_vec[expect_ix]}, y_raw);
        fail = fail + 1;
      end
      expect_ix = (expect_ix + 1) % FRAMES;
      seen = seen + 1;
      if (seen == FRAMES) begin
        $display("SUMMARY: pass=%0d fail=%0d", pass, fail);
        $finish;
      end
    end
  end

endmodule
