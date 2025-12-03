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
// Description: Top-level integrating accelerometer, kinematic calc,
//              VGA display, and shot clock seven-segment.
// 
// Dependencies: top_accel, kinematic, VGA, shotclock_top
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Basketball_Shot(
    input  wire        CLK100MHZ, 

    // VGA 
    output wire [11:0] rgb,
    output wire        VGA_HS,
    output wire        VGA_VS,
    
    // Accelerometer (ADXL362 SPI)
    input  wire        BTNC,      // shoot button
    input  wire        ACL_MISO,
    output wire        ACL_MOSI,
    output wire        ACL_SCLK,
    output wire        ACL_CSN,
    
    // Seven-Segment Shot Clock
    input  wire        BTNR,      // reset button for shot clock
    output wire [7:0]  AN,        // anode controls
    output wire [6:0]  SEG        // segment outputs
);

    //-------------
    // Accelerometer
    //-------------
    wire [15:0] x_raw,   y_raw;     // signed raw from SPI
    wire [15:0] x_flick, y_flick;   // filtered flick magnitudes
    wire [14:0] accel_led_unused;   // not used on board

    top_accel accelerometer (
        .CLK100MHZ   (CLK100MHZ), 
        .BTN_FREEZE  (1'b0),          // freeze for debug; keep filter live for main
        .ACL_MISO    (ACL_MISO), 
        .ACL_MOSI    (ACL_MOSI), 
        .ACL_SCLK    (ACL_SCLK), 
        .ACL_CSN     (ACL_CSN),
        .LED         (accel_led_unused),

        .x_raw_out   (x_raw),
        .y_raw_out   (y_raw),
        .x_flick_out (x_flick),
        .y_flick_out (y_flick)
    );

    //-------------
    // Shot clock (7-seg)
    //-------------
    wire shot_zero;

    shotclock_top shotClock (
        .CLK100MHZ (CLK100MHZ), 
        .BTNC      (1'b0),
        .BTNR      (BTNR),
        .an        (AN),
        .seg       (SEG),
        .zero      (shot_zero)
    );

    // combined reset for kinematic: manual reset OR timer expired
    wire kin_rst = BTNR | shot_zero;

    //-------------
    // Kinematic Calc
    //-------------
    wire [9:0] ball_x, ball_y;
   
    kinematic projectileMotion (
        .clk      (CLK100MHZ),
        .rst      (kin_rst),      
        .BTN      (BTNC),
        .ax_raw   (x_raw),
        .ay_raw   (y_raw),
        .ax_flick (x_flick),
        .ay_flick (y_flick),
        .ball_x   (ball_x),
        .ball_y   (ball_y)
    );
    
    //-------------
    // VGA
    //-------------
    VGA vga (
        .CLK100MHZ (CLK100MHZ), 
        .ball_x    (ball_x),
        .ball_y    (ball_y),
        .rgb       (rgb), 
        .VGA_HS    (VGA_HS),
        .VGA_VS    (VGA_VS)
    );
    
endmodule
