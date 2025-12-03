`timescale 1ns / 1ps
//iclk_genr - clock divider
// Author(s): Benjamin T, Toby P, Kevin L
// turns 100MHz system clock into 4MHz clock for SPI logic; higher clock speeds are less consistent/readable

module iclk_genr (
    input  wire CLK100MHZ,        // 100MHz system clock
    output wire clk_4MHz          // 4 MHz clock
);

    reg [4:0] counter = 5'b0;    // Counter to track clock cycles (5-bit register)
    reg       clk_reg = 1'b1;    // Internal clock register, initialized to high

    // Clock generation logic triggered on positive edge of CLK100MHZ
    always @(posedge CLK100MHZ) begin
        if (counter == 12)                   // Toggle clk_reg after 13 ticks (0-12)
            clk_reg <= ~clk_reg;

        if (counter == 24) begin             // Toggle clk_reg and reset counter after 12 more ticks (13-24)
            clk_reg    <= ~clk_reg;
            counter    <= 5'b0;               // counter reset
        end
        else
            counter <= counter + 1;           
    end

    // Assign internal clock register to output
    assign clk_4MHz = clk_reg;

endmodule
