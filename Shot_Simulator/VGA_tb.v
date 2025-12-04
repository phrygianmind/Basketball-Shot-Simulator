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
    
    // Add registers for ball position inputs
    reg [9:0] ball_x_tb = 320;  // Center of screen (640/2)
    reg [9:0] ball_y_tb = 240;  // Center of screen (480/2)
    
    // Connect all inputs including ball_x and ball_y
    VGA UUT (
        .CLK100MHZ(clk100_tb), 
        .ball_x(ball_x_tb),     // Now connected
        .ball_y(ball_y_tb),     // Now connected
        .rgb(rgb_tb), 
        .VGA_HS(VGA_HS_tb), 
        .VGA_VS(VGA_VS_tb)
    );
    
    // Clock generation (100 MHz = 10ns period)
    always #5 clk100_tb = ~clk100_tb;
    
    initial begin
        clk100_tb = 0;
        
        
        #20000000;  // Run for 20ms
        $stop;
    end
    
endmodule









