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
  reg [3:0] d1, d0;

  // outputs
  wire [7:0] an;
  wire [6:0] seg;

  // test tracking
  integer errors = 0;
  integer checks = 0;

  // Encode expected segment pattern (active-low)
  function [6:0] enc;
    input [3:0] nib;
    case (nib)
      4'h0: enc = 7'b1000000;  // 0
      4'h1: enc = 7'b1111001;  // 1
      4'h2: enc = 7'b0100100;  // 2
      4'h3: enc = 7'b0110000;  // 3
      4'h4: enc = 7'b0011001;  // 4
      4'h5: enc = 7'b0010010;  // 5
      4'h6: enc = 7'b0000010;  // 6
      4'h7: enc = 7'b1111000;  // 7
      4'h8: enc = 7'b0000000;  // 8
      4'h9: enc = 7'b0010000;  // 9
      default: enc = 7'b1111111;  // blank
    endcase
  endfunction

  // instantiate unit under test
  sevenseg_mux uut (
    .clk(clk),
    .rst(rst),
    .scan_en(scan_en),
    .d3(4'hF),  // unused digit - blank
    .d2(4'hF),  // unused digit - blank
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
    integer i;

    // Initialize with display showing "10"
    d1 = 4'd1;
    d0 = 4'd0;

    // Release reset after 50ns
    #50;
    rst = 0;

    // Wait a few clocks for mux to stabilize
    repeat(10) @(posedge clk);

    // Countdown 9 -> 0, check outputs
    for (i = 9; i >= 0; i = i - 1) begin
      d1 = i / 10;      // tens
      d0 = i % 10;      // ones
      
      // Wait for mux to cycle through both digits
      repeat(4) @(posedge clk);
      
      // Check digit 0 (an[0] should be 0, an[1] high)
      if (an[0] == 0 && an[1] == 1) begin
        checks = checks + 1;
        if (seg !== enc(d0)) begin
          $display("ERROR @ %0t: d0=%0d, expected seg=%b, got seg=%b", $time, d0, enc(d0), seg);
          errors = errors + 1;
        end
      end
      
      // Wait for next digit
      repeat(2) @(posedge clk);
      
      // Check digit 1 (an[1] should be 0, an[0] high)
      if (an[1] == 0 && an[0] == 1) begin
        checks = checks + 1;
        if (seg !== enc(d1)) begin
          $display("ERROR @ %0t: d1=%0d, expected seg=%b, got seg=%b", $time, d1, enc(d1), seg);
          errors = errors + 1;
        end
      end
      
      // Check unused anodes stay high (OFF)
      if (an[7:2] !== 6'b111111) begin
        $display("ERROR @ %0t: Unused anodes not all high, an[7:2]=%b", $time, an[7:2]);
        errors = errors + 1;
      end
      
      #80;
    end

    // Final report
    $display("\n========== Test Complete ==========");
    $display("Checks: %0d", checks);
    $display("Errors: %0d", errors);
    if (errors == 0)
      $display("PASS: All checks passed!");
    else
      $display("FAIL: %0d error(s) detected.", errors);
    $display("===================================\n");
    
    $finish;
  end

endmodule