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
    input  wire        BTNC,      // reuse as "shoot" / freeze button, etc.
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
    // Wires used
    wire [15:0] x_out, y_out;
    wire [14:0] accel_led_unused;  // internal-only LED bus from accel (not used on board)

    top_accel accelerometer (
        .CLK100MHZ (CLK100MHZ), 
        .BTN_FREEZE(BTNC), 
        .ACL_MISO  (ACL_MISO), 
        .ACL_MOSI  (ACL_MOSI), 
        .ACL_SCLK  (ACL_SCLK), 
        .ACL_CSN   (ACL_CSN),
        .LED       (accel_led_unused),
        .x_out     (x_out),
        .y_out     (y_out)
    );

    //-------------
    // Kinematic Calc
    //-------------
    // Wires Used
    wire [9:0] ball_x, ball_y;
    wire kin_rst = BTNR | shot_zero;

    kinematic projectileMotion (
        .clk    (CLK100MHZ),
        .rst    (kin_rst),      
        .BTN    (BTNC),
        .ax     (x_out),
        .ay     (y_out),
        .ball_x (ball_x),
        .ball_y (ball_y)
    );
    
    
    //-------------
    // VGA
    //-------------
    VGA vga (
        .CLK100MHZ(CLK100MHZ), 
        .ball_x   (ball_x),
        .ball_y   (ball_y),
        .rgb      (rgb), 
        .VGA_HS   (VGA_HS),
        .VGA_VS   (VGA_VS)
    );
    
    
    //-------------
    // Shot clock (7-seg)
    //-------------
    // Wires Used
    wire shot_zero;
    
    shotclock_top shotClock (
        .CLK100MHZ(CLK100MHZ), 
        .BTNC     (1'b0),
        .BTNR     (BTNR),
        .an       (AN),
        .seg      (SEG),
        .zero     (shot_zero)
    );
    
endmodule
