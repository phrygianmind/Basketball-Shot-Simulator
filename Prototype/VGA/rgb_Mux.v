`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 11:17:30 AM
// Design Name: 
// Module Name: rgb_Mux
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


module rgb_Mux(
        input wire [11:0] obj1_rgb, obj2_rgb,
        input wire obj1_on, obj2_on,
        output wire [11:0] rgb
    );
    
    // ==============================================================
    // RGB Multiplexing circuit (Priority: Lowest number is highest)
    // ==============================================================
    reg [11:0] rgb_mux_reg;
    
    always @(*)
        if(obj1_on)
            rgb_mux_reg = obj1_rgb;
        else if (obj2_on)
            rgb_mux_reg = obj2_rgb;
        else
            rgb_mux_reg = 12'h000;
    
    assign rgb = rgb_mux_reg;
    
endmodule






