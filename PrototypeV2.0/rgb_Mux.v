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
    assign rgb = (obj1_on) ? obj1_rgb : 
                 (obj2_on) ? obj2_rgb :
                             12'h000  ;
    
endmodule






