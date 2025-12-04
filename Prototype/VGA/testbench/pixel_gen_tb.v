`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2025 04:44:23 PM
// Design Name: 
// Module Name: pixel_gen_tb
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


module pixel_gen_tb(

    );
// Testbench signals
    reg clk_tb;
    reg [9:0] pixel_x_tb, pixel_y_tb;
    reg video_on_tb;
    reg [9:0] ball_x_tb, ball_y_tb;
    wire [11:0] rgb_out_tb;
    
    // Instantiate DUT
    pixel_Gen UUT (
        .pixel_x(pixel_x_tb),
        .pixel_y(pixel_y_tb),
        .video_on(video_on_tb),
        .ball_x(ball_x_tb),
        .ball_y(ball_y_tb),
        .rgb_out(rgb_out_tb)
    );
    
    // Clock generation (50 MHz = 20ns period)
    always #10 clk_tb = ~clk_tb;
    
    initial 
    begin
        // Initialize
        clk_tb = 0;
        pixel_x_tb = 0;
        pixel_y_tb = 0;
        video_on_tb = 1;
        ball_x_tb = 320;  // Center of screen
        ball_y_tb = 240;
        
        // Wait a bit
        #100;
        
        // Test 1: Basketball at center
        $display("Test 1: Basketball at center (320,240)");
        pixel_x_tb = 320;
        pixel_y_tb = 240;
        #20;
        $display("  RGB at (320,240): 0x%h", rgb_out_tb);
        
        // Test 2: Basketball hoop pole
        $display("\nTest 2: Basketball hoop pole");
        pixel_x_tb = 632;  // Pole area
        pixel_y_tb = 300;
        #20;
        $display("  RGB at (632,300): 0x%h", rgb_out_tb);
        
        // Test 3: Basketball hoop rim (red)
        $display("\nTest 3: Basketball hoop rim");
        pixel_x_tb = 620;
        pixel_y_tb = 256;
        #20;
        $display("  RGB at (620,256): 0x%h", rgb_out_tb);
        
        // Test 4: Background (black)
        $display("\nTest 4: Background area");
        pixel_x_tb = 100;
        pixel_y_tb = 100;
        #20;
        $display("  RGB at (100,100): 0x%h", rgb_out_tb);
        
        // Test 5: Move basketball
        $display("\nTest 5: Move basketball to (100,100)");
        ball_x_tb = 100;
        ball_y_tb = 100;
        #20;
        pixel_x_tb = 100;
        pixel_y_tb = 100;
        #20;
        $display("  RGB at (100,100): 0x%h", rgb_out_tb);
        
        // Test 6: Video off (should be black)
        $display("\nTest 6: video_on = 0");
        video_on_tb = 0;
        #20;
        $display("  RGB with video off: 0x%h", rgb_out_tb);
        
        // Test 7: Video back on
        $display("\nTest 7: video_on back to 1");
        video_on_tb = 1;
        #20;
        $display("  RGB with video on: 0x%h", rgb_out_tb);
        
        // Run for a bit longer
        #1000;
        
        $display("\nTestbench completed");
        $stop;
    end
    
endmodule
