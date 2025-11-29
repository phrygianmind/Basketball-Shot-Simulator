`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 05:57:56 PM
// Design Name: 
// Module Name: Basketball_Shot
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


module Basketball_Shot(
    input wire CLK100MHZ, 
    //input wire reset,             // optional can connect to a button
    //VGA 
    output wire [11:0] rgb,
    output wire VGA_HS,
    output wire VGA_VS,
    
    //Accelerometer
    input  wire        BTNC,    //Freeze button
    input  wire        ACL_MISO,
    output wire        ACL_MOSI,
    output wire        ACL_SCLK,
    output wire        ACL_CSN,
    input wire         DP,
    input wire [14:0]  LED,
    
    //Seven Seg LED
    input  wire BTNR,        // reset button
    output wire [7:0] AN,    // anode controls
    output wire [6:0] SEG    // segment outputs
    );
    
    //-------------
    // Accelerometer
    //-------------
    // Wires used
    wire [15:0] x_out, y_out;
    //wire [14:0] LED;
    //wire [6:0]  SEG;
    //wire        DP;
    //wire [7:0]  AN;
    top_accel accelerometer 
    (
        .CLK100MHZ(CLK100MHZ), 
        .BTN_FREEZE(1'b0), 
        .ACL_MISO(ACL_MISO), 
        .ACL_MOSI(ACL_MOSI), 
        .ACL_SCLK(ACL_SCLK), 
        .ACL_CSN(ACL_CSN),
        .LED(LED),
        .SEG(SEG),
        .DP(DP),
        .AN(AN),
        .x_out(x_out),
        .y_out(y_out)
     );

    //-------------
    // Kinematic Calc
    //-------------
    // Wires Used
    wire [9:0] ball_x, ball_y;
   
    kinematic projectileMotion 
    (
        .clk(CLK100MHZ),
        .rst(1'b0),
        .BTN(BTNC),
        .ax(x_out),
        .ay(y_out),
        .ball_x(ball_x),
        .ball_y(ball_y)
    );
    
    
    //-------------
    // VGA
    //-------------
    
    VGA vga 
    (
        .CLK100MHZ(CLK100MHZ), 
        .ball_x(ball_x),
        .ball_y(ball_y),
        .rgb(rgb), 
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS)
    );
    
    
    //-------------
    // Shot clock
    //-------------
    
//    shotclock_top shotClock
//    (
//        .CLK100MHZ(CLK100MHZ), 
//        .BTNC(BTNC),
//        .BTNR(BTNR),
//        .an(an),
//        .seg(seg)
//    );
    
    
    
endmodule
