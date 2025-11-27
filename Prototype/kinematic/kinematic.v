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
    input wire BTN,                            //Button
    input wire [15:0] ax, ay,                   //raw_x and raw_y
    output wire [9:0] ball_x, ball_y

    );
    
    wire CLK25MHZ;
    clockDivider clock25MhzGen2 (.CLK100MHZ(clk), .CLK25MHZ(CLK25MHZ));
    
    //Goal:
    //a_x and a_y are in LSBs per g from accelerometer. Convert it to calculable process
    //FILTER CONTROL REGISTER from acel - default at 00 is +-2g. 
    //1 LSB = 0.001 g
    //1 g   = 1000 LSB
    // So raw / LSB per g = To get no units on raw
    //Button Presses: Once pressed, start getting velocity. Once released stop measuring velocity and start updating pixel
    //Handle Button pressed
    
    // SIMPLE BOUNCE TEST
    reg [9:0] px = 100;
    reg [9:0] py = 100;
    reg dx = 1; // 1 = right, 0 = left
    reg dy = 1; // 1 = down, 0 = up
    
    reg [19:0] move_counter = 0;
    
    always @(posedge CLK25MHZ or posedge rst) 
    begin
        if (rst) 
        begin
            px <= 100;
            py <= 100;
            dx <= 1;
            dy <= 1;
            move_counter <= 0;
        end 
        else 
        begin
            move_counter <= move_counter + 1;
            
            // Move every frame (at 25MHz, 25 million cycles per second)
            if (move_counter == 25000) // Move every ~1ms
            begin
                move_counter <= 0;
                
                // Move in current direction
                if (dx) px <= px + 1;
                else px <= px - 1;
                
                if (dy) py <= py + 1;
                else py <= py - 1;
                
                // Bounce off walls
                if (px >= 635) dx <= 0;
                if (px <= 5) dx <= 1;
                if (py >= 475) dy <= 0;
                if (py <= 5) dy <= 1;
            end
        end
    end
    
    assign ball_x = px;
    assign ball_y = py;
    
endmodule











