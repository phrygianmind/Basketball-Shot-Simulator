`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 05:01:40 PM
// Design Name: 
// Module Name: kinematic
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


module kinematic(
    input wire clk,
    input wire rst,
    input wire released,
    input wire [15:0] ax, ay,                   //raw_x and raw_y
    output wire [9:0] ball_x, ball_y

    );
    //Goal:
    //a_x and a_y are in LSBs per g from accelerometer. Convert it to calculable process
    //FILTER CONTROL REGISTER from acel - default at 00 is +-2g. 
    //1 LSB = 0.001 g
    //1 g   = 1000 LSB
    // So raw / LSB per g = To get no units on raw
    
    //
    //IMPORTANT!!! - Copy and paste new to this if CHANGED LOCAL PARAMS IN VGA Module
    //
    //Local params used in VGA
    localparam BALL_RADIUS = 4;                 // Radius for 8x8 ball
    // VGA 640-by-480 sync parameters
    localparam HD = 640;    // horizontal display area
    localparam VD = 480;    // vertical display area
    // Backboard
    localparam BOARD_X_L = 630;
    localparam BOARD_X_R = 633;
    localparam BOARD_Y_T = 110;
    localparam BOARD_Y_B = 160;
    //Basketball Hoop
    localparam HOOP_X_L = 610;
    localparam HOOP_X_R = 630;
    localparam HOOP_Y_T = 155;
    localparam HOOP_Y_B = 159;
    
    //Handle x and y if signed. Bits 12-15 aren't used in Acceleometer
    // Signed 12-bit accelerometer values
    wire signed [11:0] x_val = ax[11:0];
    wire signed [11:0] y_val = ay[11:0];

    // Absolute value: magnitude only. Scalar
    wire signed [11:0] mag_x = x_val[11] ? (~x_val + 1'b1) : x_val; //2's complement to convert signed to unsigned if X & Y bit 11 from accel is 1 (Signed).
    wire signed [11:0] mag_y = y_val[11] ? (~y_val + 1'b1) : y_val;
    
    //
    // Convert raw accelerometer to fixed-point m/s^2 using Q4.12 format
    //
    // Q4.12: 4 integer bits, 12 fractional bits
    // 1 g = 1000 LSB, 9.81 m/s^2 per g
    // Fixed-point scaling: 2^12 = 4096
    // Combined constant: raw * 0.00981 * 4096 ≈ raw * 40 => 16'sd40 (Signed Decimal)

    wire signed [15:0] ax_mps2 = mag_x * 16'sd40;
    wire signed [15:0] ay_mps2 = mag_y * 16'sd40;
    
    
    //Get Velocity and Update position
    localparam signed [15:0] dt_q = 16'd41;         // dt = 0.01s Q0.12
    localparam signed [15:0] g_mps2 = 16'sd40139;  // 9.81 m/s^2 in Q4.12

    // Initial positions (Q4.12)
    //  Scale it down so it fits into 640x480 resolution pixel and when calculating
    //  init_pos / scale(50) * 4096 (2^12) = ...
    //px_init_q = 10 / 50 * 4096 = 819
    //py_init_q = 300 / 50 * 4096 = 24576

    localparam signed [15:0] px_init = 16'd819;    // 10 px -> Q4.12
    localparam signed [15:0] py_init = 16'd24576;  // 300 px -> Q4.12
    
    reg signed [15:0] vx = 0, vy = 0;                     // Q4.12
    reg signed [15:0] px = px_init, py = py_init;         // Q4.12
    
    
    //
    //Kinematic Equation y = y0 + vy0*t + -g*t^2
    //
    // Note: For VGA display, positive Y acceleration its falling. And negative Y acceleration means its rising.
    // Because Top is 0 for reference adn 480 is bottom
    always @(posedge clk or posedge rst) 
    begin
    if (rst) 
    begin
        px <= px_init;
        py <= py_init;
        vx <= 16'sd0;
        vy <= 16'sd0;
    end else if (!released) 
    begin
        // Not released: optionally sample input for initial velocity
        vx <= (ax_mps2 * dt_q) >>> 12;         // only stores potential initial x velocity
        vy <= ((ay_mps2 * dt_q) >>> 12);      // only stores potential initial y velocity 
        px <= px_init;
        py <= py_init;
    end else begin
        // Released: update position using stored vx, vy
        px <= px + ((vx * dt_q) >>> 12);
        vy <= vy + -((g_mps2 * dt_q) >>> 12);   // gravity pulls down
        py <= py + ((vy * dt_q) >>> 12);
    end
end
    
    //
    //Apply Momentum Principles for bouncing back
    //
    //Code - In progress
    
    
    
    
    
    
    //
    // Convert and Map position to VGA (640x480)
    //
    wire signed [31:0] px_pix = (px >>> 12) * 50;
    wire signed [31:0] py_pix = VD - ((py >>> 12) * 50); // flip for VGA

    assign ball_x = (px_pix < 0)      ? 10'd0 :
                    (px_pix > 639)    ? 10'd639 :
                    px_pix[9:0];

    assign ball_y = (py_pix < 0)      ? 10'd0 :
                    (py_pix > 479)    ? 10'd479 :
                    py_pix[9:0];

endmodule












