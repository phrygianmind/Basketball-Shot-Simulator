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
        output wire hsync , vsync , video_on , p_tick,
        output wire [9:0] pixel_x, pixel_y 
    );
    
     
    //Define Constants
    // VGA 640-by-480 sync parameters
    localparam HD = 640; // horizontal display area
    localparam HF = 48 ; // h. front (left) border
    localparam HB = 16 ; // h. back (right) border
    localparam HR = 96 ; // h. retrace
    localparam VD = 480; // vertical display area
    localparam VF = 10; // v. front (top) border
    localparam VB = 33; // v. back (bottom) border
    localparam VR = 2; // v. retrace 
    
    // mod - 4 counter 
    // reg [1:0] mod4_reg;
    // wire [1:0] mod4_next;
    
    
    // sync counters
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg , v_count_next;
    // output buffer
    reg v_sync_reg , h_sync_reg ;
    wire v_sync_next , h_sync_next ;
    // status signal
    wire h_end , v_end , pixel_tick;
    
    //Use external 25Mhz clock divider so Mod 4 stuff is commented out
    assign pixel_tick = 1'b1;

    
    // body
    // registers
    always @ (posedge clk , posedge reset)
    begin
        if (reset)
        begin 
            //mod4_reg <= 2'b00;
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg <= 1'b0;
            h_sync_reg <= 1'b0;
        end
        else
        begin
            //mod4_reg <= mod4_next;
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg <= v_sync_next;
            h_sync_reg <= h_sync_next;
        end 
    end
     
    // mod-4 circuit to generate 25 MHz enable tick from 100MHZ clk
    // assign mod4_next = mod4_reg + 1'b1;
    //assign pixel_tick = (mod4_reg == 2'b11);              //Check if mod4_reg counter reaches 3
    
    
    // status signals
    // end of horizontal counter (799)
    assign h_end = (h_count_reg == (HD+HF+HB+HR-1));
    // end of vertical counter (524)
    assign v_end = (v_count_reg == (VD+VF+VB+VR-1)); 
    
    // next-state logic of mod-800 horizontal sync counter
    always @(*)
    begin
        if (pixel_tick) // 25 MHz pulse
            if (h_end)
                h_count_next = 0;
            else
                h_count_next = h_count_reg + 1;
        else
            h_count_next = h_count_reg;
        
    end
    
    // next-state logic of mod-525 vertical sync counter
    always @(*)
    begin
        if (pixel_tick & h_end)
            if (v_end)
                v_count_next = 0;
            else
                v_count_next = v_count_reg + 1;
        else
            v_count_next = v_count_reg; 
    end
    
    
    
    
    // horizontal and vertical sync, buffered to avoid glitch
    // h-svnc-next asserted between 656 and 751
    assign h_sync_next = ~(h_count_reg >= (HD+HB) && h_count_reg <= (HD+HB+HR-1));
    // vh-sync-next asserted between 490 and 491
    assign v_sync_next = ~(v_count_reg>=(VD+VB) && v_count_reg <= (VD+VB+VR-1)); 
    
    
    
    
    // video on/off
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD);
    // output
    assign hsync = h_sync_reg;
    assign vsync = v_sync_reg;
    assign pixel_x = h_count_reg;
    assign pixel_y = v_count_reg;
    assign p_tick = pixel_tick;
    
endmodule













