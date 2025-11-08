`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 11:20:50 AM
// Design Name: 
// Module Name: pixel_Gen
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


module pixel_Gen(
    input wire [9:0] pixel_x, pixel_y,
    input wire video_on,
    input wire [9:0] ball_x, ball_y,
    output wire [11:0] rgb_out

    );
    
    //Delcare wires
    wire [9:0] ball_x_in, ball_y_in;
    assign ball_x_in = ball_x;
    assign ball_y_in = ball_y;
    //Declare objects
    wire [11:0] obj1_rgb;
    wire obj1_on;
    basketballHoop object1 (.video_on(video_on), .pixel_x(pixel_x), .pixel_y(pixel_y), 
                                     .object_rgb(obj1_rgb), .object_on(obj1_on));
    
    //In progress - Need to get (x,y) ball 
    wire [11:0] obj2_rgb;
    wire obj2_on;
    basketball object2 (.video_on(video_on), .pixel_x(pixel_x), .pixel_y(pixel_y), 
                        .ball_x(ball_x_in), .ball_y(ball_y_in),
                        .object_rgb(obj2_rgb), .object_on(obj2_on));


    //Use rgb mux to determine what rgb output should a pixel be
    rgb_Mux rgb_MuxCkt (.obj1_rgb(obj1_rgb), .obj1_on(obj1_on), .obj2_rgb(obj2_rgb), .obj2_on(obj2_on), .rgb(rgb_out));
    
    
endmodule












