`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2025 04:34:11 PM
// Design Name: 
// Module Name: sevenseg_tb
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


module sevenseg_tb();

  // clock / reset
  reg clk = 0;
  reg rst = 1;

  // sevenseg inputs
  reg scan_en = 0;
  reg [3:0] d3, d2, d1, d0;

  // outputs
  wire [7:0] an;
  wire [6:0] seg;

  integer errors = 0;
  integer steps  = 0;
  integer val;

  // instantiate unit under test
  sevenseg_mux uut (
    .clk(clk),
    .rst(rst),
    .scan_en(scan_en),
    .d3(d3),
    .d2(d2),
    .d1(d1),
    .d0(d0),
    .an(an),
    .seg(seg)
  );

  // 100 MHz clock
  always #5 clk = ~clk;

  // make scan_en permanently enabled after reset (remove pulser)
  always @(posedge clk) begin
    if (rst) scan_en <= 0;
    else     scan_en <= 1;
  end

  initial begin
    // initial values
    d3 = 4'hF;
    d2 = 4'hF;
    d1 = 4'd1;
    d0 = 4'd0;

    // hold reset small time, then run
    #50; rst = 0;

    // countdown 10 -> 00 within ~1000 ns runtime
    // step every 80 ns (11 steps = 880 ns plus reset time)
    repeat (10) begin
      #80;
      if (d0 == 0) begin
        d0 = 4'd9;   // blocking for immediate TB visibility
        d1 = d1 - 1;
      end else begin
        d0 = d0 - 1;
      end
      steps = steps + 1;
      // Self-check expected values for 10->09->...->01 using arithmetic
      if (steps <= 9) begin
        val = 10 - steps; // 9..1
        if (d1 !== (val/10) || d0 !== (val%10)) begin
          $display("[ERROR] Step %0d unexpected d1=%0d d0=%0d", steps, d1, d0);
          errors = errors + 1;
        end else begin
          $display("[OK] Step %0d d1=%0d d0=%0d", steps, d1, d0);
        end
      end else begin
        // step 10 should be 01 -> handled in final step below
      end
    end

    // final step to reach 00 from 01
    #80; d0 = 4'd0; d1 = 4'd0; steps = steps + 1;
    if (d1 !== 4'd0 || d0 !== 4'd0) begin
      $display("[ERROR] Final step unexpected d1=%0d d0=%0d", d1, d0);
      errors = errors + 1;
    end else begin
      $display("[OK] Final step d1=%0d d0=%0d", d1, d0);
    end

    // finish at ~1010 ns total
    #10;
    if (errors == 0) $display("[PASS] Countdown 10->00 verified in %0d steps", steps);
    else             $display("[FAIL] %0d errors during countdown", errors);
    $finish;
  end

endmodule