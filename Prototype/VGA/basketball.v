`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 01:35:21 PM
// Design Name: 
// Module Name: basketball
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


module basketball(
        input video_on,
        input wire [9:0] pixel_x, pixel_y,
        input wire [9:0] ball_x, ball_y,
        output wire [11:0] object_rgb,
        output wire object_on

    );
    
    
    /// ==============================================================
    // Round Ball - Bitmasking
    // ==============================================================
    
    localparam BALL_RADIUS = 4;  // Radius for 8x8 ball
    wire [9:0] ball_x_l, ball_x_r, ball_y_t, ball_y_b;
    
    // Calculate ball boundaries (8x8 region)
    assign ball_x_l = ball_x - BALL_RADIUS;
    assign ball_x_r = ball_x + BALL_RADIUS - 1;  // -1 to make it 8 pixels wide
    assign ball_y_t = ball_y - BALL_RADIUS;
    assign ball_y_b = ball_y + BALL_RADIUS - 1;  // -1 to make it 8 pixels tall
    
    
    // ROM for circular ball pattern (8x8)
    wire [2:0] rom_addr, rom_col;
    reg [7:0] rom_data;
    wire rom_bit;
    
    always @(*)
    begin
        case(rom_addr)
            3'h0: rom_data = 8'b00111100;   //   ****  
            3'h1: rom_data = 8'b01111110;   //  ******
            3'h2: rom_data = 8'b11111111;   // ********
            3'h3: rom_data = 8'b11111111;   // ********
            3'h4: rom_data = 8'b11111111;   // ********
            3'h5: rom_data = 8'b11111111;   // ********
            3'h6: rom_data = 8'b01111110;   //  ******
            3'h7: rom_data = 8'b00111100;   //   **** 
        endcase
    end
    
    // Check if pixel is within ball's bounding box
    wire ball_region_on;
    assign ball_region_on = (pixel_x >= ball_x_l) && (pixel_x <= ball_x_r) &&
                            (pixel_y >= ball_y_t) && (pixel_y <= ball_y_b);
                           
    
    // ==============================================================
    // map current pixel location to ROM addr/col
    // ==============================================================
    
    // Map current pixel to ROM address (relative to ball top-left)
    assign rom_addr = pixel_y[2:0] - ball_y_t[2:0];
    assign rom_col = pixel_x[2:0] - ball_x_l[2:0];
    assign rom_bit = rom_data[rom_col];  // Use correct bit ordering
    
    // Final ball pixel (within region AND ROM bit is set)
    wire basketball_on;
    assign basketball_on = ball_region_on && rom_bit;
                           
    // ==============================================================
    // Colors
    // ==============================================================
    
    localparam [11:0] BLACK = 12'h000;
    localparam [11:0] ORANGE = 12'hFA0;
    
    assign object_rgb = (~video_on)     ? BLACK  :
                        (basketball_on) ? ORANGE : 
                                          BLACK  ;
    
    assign object_on = basketball_on;

    
    
endmodule













