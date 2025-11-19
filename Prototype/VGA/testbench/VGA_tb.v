`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2025 08:27:38 PM
// Design Name: 
// Module Name: VGA_tb
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


module VGA_tb(

    );
    reg clk100_tb;
    wire [11:0] rgb_tb;
    wire VGA_HS_tb;
    wire VGA_VS_tb;
    
    VGA UUT (.CLK100MHZ(clk100_tb), .rgb(rgb_tb), .VGA_HS(VGA_HS_tb), .VGA_VS(VGA_VS_tb));
    
    //Period
    always #5 clk100_tb = ~clk100_tb;
    
    
    initial
    begin
        clk100_tb = 0;
        #20000000;
        $stop;
    end
    
    
    
endmodule








