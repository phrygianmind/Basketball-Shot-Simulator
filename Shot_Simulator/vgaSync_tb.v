`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2025 11:37:58 AM
// Design Name: 
// Module Name: vgaSync_tb
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


module vgaSync_tb(

    );
    reg clk_tb, reset_tb;
    wire hysnc_tb, vynsc_tb, video_on_tb, p_tick;
    wire [9:0] pixel_x_tb, pixel_y_tb;
    
    
    vga_sync UUT (.clk(clk_tb), .reset(reset_tb), 
                  .hsync(hysnc_tb), .vsync(vynsc_tb), .video_on(video_on_tb), .p_tick(p_tick), 
                  .pixel_x(pixel_x_tb), .pixel_y(pixel_y_tb));
                  
    always #1 clk_tb = ~clk_tb;
    
    initial 
    begin
        clk_tb = 0;
        reset_tb = 0;
        #20000000;
        $stop;
    end
    
    
    
endmodule





