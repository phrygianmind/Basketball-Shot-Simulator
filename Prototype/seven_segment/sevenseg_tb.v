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
  wire [3:0] an;
  wire [6:0] seg;

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
    // Waveform-only testbench for seven-segment display verification
    // Initialize with blank displays (F = blank in encoder)
    d3 = 4'hF;
    d2 = 4'hF;
    d1 = 4'hF;
    d0 = 4'hF;

    // Release reset after 100ns
    #100;
    rst = 0;

    // Test case 1: Display "10" (d1=1, d0=0)
    #100;
    d1 = 4'd1;
    d0 = 4'd0;

    // Test case 2: Count down from 09 to 00
    #500;  d1=4'd0; d0=4'd9;
    #500;  d0=4'd8;
    #500;  d0=4'd7;
    #500;  d0=4'd6;
    #500;  d0=4'd5;
    #500;  d0=4'd4;
    #500;  d0=4'd3;
    #500;  d0=4'd2;
    #500;  d0=4'd1;
    #500;  d0=4'd0;

    // Test case 3: All digits 0-9 on both displays
    #500;
    d1 = 4'd2;
    d0 = 4'd4;
    #500;
    d1 = 4'd5;
    d0 = 4'd5;
    #500;
    d1 = 4'd8;
    d0 = 4'd8;
    #500;
    d1 = 4'd9;
    d0 = 4'd9;

    // Hold final state and observe multiplexing
    #2000;
    
    $finish;
  end

endmodule