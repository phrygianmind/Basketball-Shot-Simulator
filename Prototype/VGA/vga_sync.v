`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2025 01:42:50 PM
// Design Name: 
// Module Name: vga_sync
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


module vga_sync(
    input wire clk, reset,
    output wire hsync, vsync, video_on, p_tick,
    output wire [9:0] pixel_x, pixel_y 
);
    
    // VGA 640-by-480 sync parameters
    localparam HD = 640;    // horizontal display area
    localparam HF = 48 ;    // h. front (left) border
    localparam HB = 16 ;    // h. back (right) border
    localparam HR = 96 ;    // h. retrace
    localparam VD = 480;    // vertical display area
    localparam VF = 10;     // v. front (top) border
    localparam VB = 33;     // v. back (bottom) border
    localparam VR = 2;      // v. retrace 
    
    reg [9:0] h_count_reg = 0;
    reg [9:0] v_count_reg = 0;
    reg v_sync_reg = 1'b0, h_sync_reg = 1'b0;
    
    wire h_end, v_end;
    wire pixel_tick;
    assign pixel_tick = 1'b1;  

    
    always @(posedge clk or posedge reset)
    begin
        if (reset) begin
            h_count_reg <= 0;
            v_count_reg <= 0;
            h_sync_reg <= 1'b0;
            v_sync_reg <= 1'b0;
        end
        else begin
            // Horizontal counter
            if (h_end)
                h_count_reg <= 0;
            else
                h_count_reg <= h_count_reg + 1;
            
            // Vertical counter
            if (h_end) begin
                if (v_end)
                    v_count_reg <= 0;
                else
                    v_count_reg <= v_count_reg + 1;
            end
            
            // Sync signals
            h_sync_reg <= ~(h_count_reg >= (HD+HB) && h_count_reg <= (HD+HB+HR-1));
            v_sync_reg <= ~(v_count_reg >= (VD+VB) && v_count_reg <= (VD+VB+VR-1));
        end
    end
    
    assign h_end = (h_count_reg == (HD+HF+HB+HR-1));
    assign v_end = (v_count_reg == (VD+VF+VB+VR-1));
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD);
    assign hsync = h_sync_reg;
    assign vsync = v_sync_reg;
    assign pixel_x = h_count_reg;
    assign pixel_y = v_count_reg;
    assign p_tick = pixel_tick;
    
endmodule













