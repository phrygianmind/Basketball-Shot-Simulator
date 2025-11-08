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
        //input wire reset,             // optional can connect to a button
        output wire [11:0] rgb,
        output wire VGA_HS,
        output wire VGA_VS
    );
    
    //Declare essential wires/registers
    wire CLK25MHZ;
    wire hsync, vsync, video_on, p_tick;
    wire [9:0] pixel_x, pixel_y;
    wire [11:0] rgb_next; 
    reg [11:0] rgb_reg;
    
    wire reset = 1'b0;
    
    clockDivider clock25MhzGen (.CLK100MHZ(CLK100MHZ), .CLK25MHZ(CLK25MHZ));
    
    vga_sync vga_syncCkt (.clk(CLK25MHZ) , .reset(reset), 
                          .hsync(hsync), .vsync(vsync), 
                          .video_on(video_on), .p_tick(p_tick), 
                          .pixel_x(pixel_x), .pixel_y(pixel_y)
    );
    
    //ball_x and ball_y are coordinates supposed to be inputted
    pixel_Gen pixel_genCkt (.pixel_x(pixel_x), .pixel_y(pixel_y), .video_on(video_on), .rgb_out(rgb_next),
                            .ball_x(10), .ball_y(300));
    
    
    //rgb buffer. Use registers instead of wires to store
    always @(posedge CLK25MHZ or posedge reset)
    begin
        if (reset)
            rgb_reg <= 12'h000;
        else if (p_tick)
            rgb_reg <= rgb_next;
    end
    
    // Assign outputs
    assign rgb = rgb_reg;
    assign VGA_HS = hsync;
    assign VGA_VS = vsync;
    
    
    
endmodule








