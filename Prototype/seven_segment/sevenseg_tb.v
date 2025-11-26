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
  wire [3:0] an;
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
    // Waveform-only testbench for seven-segment display verification
    // Initialize with display showing "10"
    d1 = 4'd1;
    d0 = 4'd0;

    // Release reset after 50ns
    #50;
    rst = 0;

    // Quick countdown sequence
    #200;  d1=4'd0; d0=4'd9;  // 09
    #200;  d0=4'd5;           // 05
    #200;  d0=4'd3;           // 03
    #200;  d0=4'd0;           // 00

    // Observe multiplexing with final value
    #150;
    
    $finish;
  end

endmodule