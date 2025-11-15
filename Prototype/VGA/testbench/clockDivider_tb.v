`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2025 12:25:52 PM
// Design Name: 
// Module Name: clockDivider_tb
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


module clockDivider_tb(

    );
    reg CLK100MHZ_tb;
    wire CLK25MHZ_tb;
    
    clockDivider UUT (.CLK100MHZ(CLK100MHZ_tb),  .CLK25MHZ(CLK25MHZ_tb));
    
    // Generate 100 MHz clock: period = 10 ns -> toggle every 5 ns
    initial begin
        CLK100MHZ_tb = 0;
        forever #5 CLK100MHZ_tb = ~CLK100MHZ_tb;
    end
    
    //  run simulation for a certain time then finish
    initial begin
        #200;  // Run for 200 ns
        $finish;
    end
    
    
endmodule





