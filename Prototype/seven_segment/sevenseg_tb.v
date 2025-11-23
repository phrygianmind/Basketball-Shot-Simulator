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
    // initial values
    d3 = 4'hF;
    d2 = 4'hF;
    d1 = 4'd1;
    d0 = 4'd0;

    // hold reset small time, then run
    #100; rst = 0;

    // compressed value changes (each 50 ns apart)
    #50;   d3=4'd0; d2=4'd1; d1=4'd2; d0=4'd3;
    #50;   d3=4'd4; d2=4'd5; d1=4'd6; d0=4'd7;
    #50;   d3=4'd8; d2=4'd9; d1=4'hA; d0=4'hB;
    #50;   d3=4'hC; d2=4'hD; d1=4'hE; d0=4'hF;

    // later small adjustments to d0/d1
    #200;  d0=4'd9; d1=4'd0;
    #200;  d0=4'd5; d1=4'd0;
    #200;  d0=4'd0; d1=4'd1;

    // extend sim so multiple scan cycles visible
    #5000; $finish;
  end

endmodule