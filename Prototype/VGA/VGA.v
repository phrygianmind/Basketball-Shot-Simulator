`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 11:03:49 AM
// Design Name: 
// Module Name: VGA
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


module VGA(
        input CLK100MHZ, 
        input wire [2:0] SW,
        input wire reset,             // optional can connect to a button
        output wire [2:0] rgb,
        output wire VGA_HS,
        output wire VGA_VS
    );
    
    //Declare wires
    wire CLK25MHZ;
    wire hsync, vsync, video_on, p_tick;
    wire [9:0] pixel_x, pixel_y;
    
    clockDivider clock25MhzGen (.CLK100MHZ(CLK100MHZ), .CLK25MHZ(CLK25MHZ));
    
    vga_sync vga_syncCkt (.clk(CLK25MHZ) , .reset(1'b0), 
                          .hsync(VGA_HS), .vsync(VGA_VS), 
                          .video_on(video_on), .p_tick(p_tick), 
                          .pixel_x(pixel_x), .pixel_y(pixel_y)
    );
    
    
    //Do VGA test module here.
    // Instantiate VGA test module
    vga_test vga_test_unit (
        .clk(CLK25MHZ),   // 25 MHz pixel clock
        .reset(1'b0),
        .sw(SW),          // 3-bit switch input
        .rgb(rgb)         // 3-bit RGB output
    );
    
    
    
    
endmodule








