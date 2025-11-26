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
    input wire [15:0] ax, ay,       //raw_x and raw_y
    output wire [9:0] ball_x, ball_y

    );
    //Goal:
    //a_x and a_y are in LSBs per g from accelerometer. Convert it to calculable process
    //FILTER CONTROL REGISTER from acel - default at 00 is +-2g. 
    //1 LSB = 0.001 g
    //1 g   = 1000 LSB
    // So raw / LSB per g = To get no units on raw
    
    //Local params used in VGA
    
    
    //Handle x and y if signed. Bits 12-15 aren't used in Acceleometer
    // Signed 12-bit accelerometer values
    wire signed [11:0] x_val = ax[11:0];
    wire signed [11:0] y_val = ay[11:0];

    // Absolute value: magnitude only. Scalar
    wire signed [11:0] mag_x = x_val[11] ? (~x_val + 1'b1) : x_val; //2's complement to convert signed to unsigned if X & Y bit 11 from accel is 1 (Signed).
    wire signed [11:0] mag_y = y_val[11] ? (~y_val + 1'b1) : y_val;
    
    
    // Convert raw accelerometer to fixed-point m/s^2 using Q4.12 format
    // Q4.12: 4 integer bits, 12 fractional bits
    // 1 g = 1000 LSB, 9.81 m/s^2 per g
    // Fixed-point scaling: 2^12 = 4096
    // Combined constant: raw * 0.00981 * 4096 ≈ raw * 40 => 16'sd40 (Signed Decimal)

    wire signed [15:0] ax_mps2 = mag_x * 16'sd40;
    wire signed [15:0] ay_mps2 = mag_y * 16'sd40;
    
    
    //Get Velocity and Update position
    localparam signed [15:0] dt_q = 16'd41;     // dt = 0.01 s Q0.12
    localparam BALL_RADIUS = 4;                 // Radius for 8x8 ball

    // Initial positions (Q4.12)
    //px_init_q = 10 / 50 * 4096 = 819
    //py_init_q = 300 / 50 * 4096 = 24576

    localparam signed [15:0] px_init = 16'd819;    // 10 px -> Q4.12
    localparam signed [15:0] py_init = 16'd24576;  // 300 px -> Q4.12
    
    reg signed [15:0] vx = 0, vy = 0; // Q4.12
    reg signed [15:0] px = 0, py = 0; // Q4.12
    
    //Kinematic Equation y = y0 + vy0*t + -g*t^2
    always @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            vx <= 16'sd0; vy <= 16'sd0;
            px <= px_init; py <= py_init;
        end 
        else 
        begin
            vx <= vx + ((ax_mps2 * dt_q) >>> 12);
            vy <= vy + ((ay_mps2 * dt_q) >>> 12);
    
            px <= px + ((vx * dt_q) >>> 12) + ((ax_mps2 * dt_q * dt_q) >>> 13);
            py <= py + ((vy * dt_q) >>> 12) + ((ay_mps2 * dt_q * dt_q) >>> 13);
        end
    end
    
    
    // Convert and Map Q4.12 position to VGA (640x480)
    
    wire signed [31:0] px_pix = (px >>> 12) * 50;
    wire signed [31:0] py_pix = (py >>> 12) * 50;
    
    assign ball_x = (px_pix < 0)      ? 10'd0 :
                    (px_pix > 639)    ? 10'd639 :
                    px_pix[9:0];
    
    // Flip Y-axis so 0 at top
    wire signed [31:0] py_flip = 480 - py_pix;
    assign ball_y = (py_flip < 0)      ? 10'd0 :
                    (py_flip > 479)    ? 10'd479 :
                    py_flip[9:0];
endmodule












