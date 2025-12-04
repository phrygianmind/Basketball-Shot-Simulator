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


module kinematic
(
    input wire clk,
    input wire rst,
    input wire BTN,                            //Button
    input wire [15:0] ax, ay,                  //raw_x and raw_y
    output wire [9:0] ball_x, ball_y,
    output wire [3:0] LED

);
    // 60Hz Physics Clock
    reg [20:0] physics_counter = 0;
    wire physics_clk = (physics_counter == 21'd1_666_666);
    
    always @(posedge clk) 
    begin
        physics_counter <= physics_counter + 1;
        if (physics_counter == 21'd1_666_666) 
            physics_counter <= 0;
    end
    
    // SIMPLE BUTTON - Same clock domain as FSM
    reg btn_prev = 0;
    reg pressed_edge = 0;
    reg released_edge = 0;
    
    always @(posedge physics_clk) 
    begin
        btn_prev <= BTN;
        pressed_edge <= (BTN && !btn_prev);
        released_edge <= (!BTN && btn_prev);
    end

    // Local params used in VGA
    localparam BALL_RADIUS = 4;
    localparam HD = 640;
    localparam VD = 480;
    
    //FSM
    localparam [3:0] 
        START       = 4'd0, 
        PRESSED     = 4'd1, 
        RELEASED    = 4'd2, 
        DONE        = 4'd3; 
    reg [3:0] STATE = START;
    
    reg [3:0] LEDhold = 4'b0000;
    assign LED = LEDhold;
    
    // Essential calculation regs/wires
    localparam [9:0] px_init = 50;
    localparam [9:0] py_init = 50;
    
    reg [9:0] px = px_init, py = py_init;
    reg signed [15:0] vx = 0, vy = 0;
    
    // TUNE THESE VALUES until it FEELS right:
    localparam GRAVITY = 4;
    localparam ACCEL_SENSITIVITY = 6;
    localparam VELOCITY_SCALE = 6;
    
    // signed 12-bit values and magnitudes - Decode
    wire signed [11:0] x_signed = ax[11:0];
    wire signed [11:0] y_signed = ay[11:0];
    wire neg_x = x_signed[11];
    wire neg_y = y_signed[11];
    wire [11:0] mag_x = neg_x ? (~x_signed + 12'd1) : x_signed;
    wire [11:0] mag_y = neg_y ? (~y_signed + 12'd1) : y_signed;
    
    // FSM - All on same clock domain
    always @(posedge physics_clk)
    begin 
        if (rst)
        begin
            px <= px_init; 
            py <= py_init;
            vx <= 0; 
            vy <= 0;
            STATE <= START;
            LEDhold <= 4'b0000;
        end
        else begin
            case(STATE)
                START:
                begin
                    px <= px_init; 
                    py <= py_init;
                    vx <= 0; 
                    vy <= 0;
                    LEDhold <= 4'b0001;
                    
                    if (pressed_edge) 
                    begin
                        STATE <= PRESSED;
                        LEDhold <= 4'b0010;
                    end
                    else
                    begin
                        STATE <= START;
                    end
                end
                
                PRESSED:
                begin
                    LEDhold <= 4'b0010;
                    
                    if (released_edge)
                    begin
                        // HARDCODE FOR TESTING - ball moves up and right
                        vx <= 100;
                        vy <= 150;
                        STATE <= RELEASED;
                        LEDhold <= 4'b0100;
                    end
                    else
                    begin
                        // Normal acceleration accumulation
                        vx <= vx + (mag_x[11:0] >>> ACCEL_SENSITIVITY);
                        vy <= vy + (mag_y[11:0] >>> ACCEL_SENSITIVITY); 
                        STATE <= PRESSED;
                    end
                end
                
                RELEASED:
                begin
                    // Update position
                    px <= px + (vx >>> VELOCITY_SCALE);
                    py <= py + (vy >>> VELOCITY_SCALE);
                    
                    // Apply gravity
                    vy <= vy - GRAVITY;
                    
                    LEDhold <= 4'b0100;
                    STATE <= RELEASED;
                    
                    // Reset if ball goes off screen
                    if (px > HD || py < 10 || py > VD) 
                    begin
                        STATE <= DONE;
                        LEDhold <= 4'b1000;
                    end
                end
                
                DONE:
                begin
                    px <= px_init; 
                    py <= py_init;
                    vx <= 0; 
                    vy <= 0;
                    STATE <= START;
                    LEDhold <= 4'b0001;
                end
        
                default:
                begin
                    STATE <= START;
                    LEDhold <= 4'b1111;
                end
            endcase
        end
    end
    
    // Assign Coordinates - Flip Y
    assign ball_x = (px <= BALL_RADIUS) ? BALL_RADIUS :
                   (px >= (HD - 1) - BALL_RADIUS) ? (HD - 1) - BALL_RADIUS :
                   px;
    
    assign ball_y = (py <= BALL_RADIUS) ? ((VD - 1) - BALL_RADIUS) :
                   (py >= (VD - 1) - BALL_RADIUS) ? ((VD - 1) - BALL_RADIUS) :
                   ((VD - 1) - py);

endmodule











