`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2025 11:40:11 AM
// Design Name: 
// Module Name: clockDivider
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


module clockDivider(
    input CLK100MHZ, 
    output reg CLK25MHZ = 0  // Initialize to 0
);

    reg [1:0] counter = 2'b00;
    
    /*
    Math:
    
        Period: 1/100Mhz = 10ns
        Period: 1/25Mhz = 40ns
        
        Since 25Mhz has a period of 40ns, It will be on 40ns/2 and off for the rest of time. Therefore switch every 20ns
        
        With original clock (100Mhz) it has a 10ns period. Therefore 2 periods will be 20ns (25Mhz) period. 
        So it will turn 25Mhz at 2
    
    */
    
    always @(posedge CLK100MHZ) 
    begin
        if (counter == 2'b01)  // When counter reaches 1 (after 2 clock cycles)
        begin
            CLK25MHZ <= ~CLK25MHZ;  // Toggle output
            counter <= 2'b00;       // Reset counter
        end
        else
        begin
            counter <= counter + 1; // Increment counter
        end
    end

endmodule


   













