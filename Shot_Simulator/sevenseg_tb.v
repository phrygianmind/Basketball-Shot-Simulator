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

    // Countdown 9 -> 0, 80ns per step (total ~50 + 80*11 + 70 = 1000ns)
    for (i = 9; i >= 0; i = i - 1) begin
      #80;
      d1 = i / 10;      // tens
      d0 = i % 10;      // ones
    end

    #70;
    $finish;
  end

endmodule