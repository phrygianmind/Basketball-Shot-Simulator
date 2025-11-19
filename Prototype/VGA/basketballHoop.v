`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 12:36:38 PM
// Design Name: 
// Module Name: basketballHoop
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


module basketballHoop(
        input video_on,
        input wire [9:0] pixel_x, pixel_y,
        output wire [11:0] object_rgb,
        output wire object_on
    );
    // ==============================================================
    // Screen coordinates (0,0) to (639,479)
    // ==============================================================

    // Basketball pole coordinates lvl#3
    localparam POLE_X_L = 630;
    localparam POLE_X_R = 635;
    localparam POLE_Y_T = 120;
    localparam POLE_Y_B = 480;

    // Backboard coordinates lvl#2
    localparam BOARD_X_L = 630;
    localparam BOARD_X_R = 633;
    localparam BOARD_Y_T = 110;
    localparam BOARD_Y_B = 160;
    
    //Basketball Hoop (Higher overlay priority) lvl #1
    localparam HOOP_X_L = 610;
    localparam HOOP_X_R = 630;
    localparam HOOP_Y_T =  155;
    localparam HOOP_Y_B = 159;

    // ==============================================================
    // Object signals
    // ==============================================================

    wire pole_on, board_on, hoop_on;
    
    assign pole_on  = (pixel_x >= POLE_X_L)  && (pixel_x <= POLE_X_R)  &&
                      (pixel_y >= POLE_Y_T)  && (pixel_y <= POLE_Y_B);

    assign board_on = (pixel_x >= BOARD_X_L) && (pixel_x <= BOARD_X_R) &&
                      (pixel_y >= BOARD_Y_T) && (pixel_y <= BOARD_Y_B);
                      
    assign hoop_on = (pixel_x >= HOOP_X_L) && (pixel_x <= HOOP_X_R) &&
                     (pixel_y >= HOOP_Y_T) && (pixel_y <= HOOP_Y_B);
                      
    assign object_on = pole_on || board_on || hoop_on;

    // ==============================================================
    // Colors
    // ==============================================================
    
    //Metallic gray pole
    localparam [11:0] GRAY = 12'h555;
    //White Backboard
    localparam [11:0] WHITE = 12'hFFF;
    //Black
    localparam [11:0] BLACK = 12'h000;
    //Red
    localparam [11:0] RED = 12'hF00;
    
    // {VGA_R, VGA_G, VGA_B} Each VGA_X = 4 bits
    assign object_rgb = (~video_on) ? BLACK :
                        (hoop_on)   ? RED   :
                        (board_on)  ? WHITE :
                        (pole_on)   ? GRAY  :
                                      BLACK ;
    
    
    
endmodule
















