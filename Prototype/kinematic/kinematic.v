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
    output wire [9:0] ball_x, ball_y

);
    //Goal:
    //a_x and a_y are in LSBs per g from accelerometer. Convert it to calculable process
    //FILTER CONTROL REGISTER from acel - default at 00 is +-2g. 
    //1 LSB = 0.001 g
    //1 g   = 1000 LSB
    //
    //Button Presses: Once pressed, start getting velocity. Once released stop measuring velocity and start updating pixel
    //Handle Button pressed
    
    // d50_000_000 (500ms)
    // d1_666_666 (16.7ms)
    // 60Hz Physics Clock (16.7ms period)
    reg [20:0] physics_counter = 0;
    wire physics_clk = (physics_counter == 21'd50_000_000); // 100MHz/60Hz
    
    always @(posedge clk) 
    begin
        physics_counter <= physics_counter + 1;
        if (physics_counter == 21'd50_000_000) 
            physics_counter <= 0;
    end
    
    // Button Handler
    wire btn_db_w;
    btn_debouncer db 
    (
        .clk    (clk),
        .btn_in (BTN),
        .btn_db (btn_db_w)
    );
    
    //Record Button presses
    reg btn_prev = 0;
    reg pressed = 0;
    reg pressed_edge = 0;
    reg released = 0;
    
    always @(posedge clk) 
    begin
        btn_prev <= btn_db_w;
        pressed <= btn_db_w;
        pressed_edge <= (btn_db_w && !btn_prev);   // rising edge
        released <= (!btn_db_w && btn_prev);       // falling edge
    end

    //
    //IMPORTANT!!! - Copy and paste new to this if CHANGED LOCAL PARAMS IN VGA Module
    //
    //Local params used in VGA
    localparam BALL_RADIUS = 4;                 // Radius for 8x8 ball
    // VGA 640-by-480 sync parameters
    localparam HD = 640;    // horizontal display area
    localparam VD = 480;    // vertical display area
    // Backboard
    localparam BOARD_X_L = 630;
    localparam BOARD_X_R = 633;
    localparam BOARD_Y_T = 200;
    localparam BOARD_Y_B = 260;
    //Basketball Hoop
    localparam HOOP_X_L = 610;
    localparam HOOP_X_R = 630;
    localparam HOOP_Y_T = 254;
    localparam HOOP_Y_B = 258;
    
    
    // signed 12-bit values and magnitudes - Decode
    wire signed [11:0] x_signed = ax[11:0];
    wire signed [11:0] y_signed = ay[11:0];
    wire neg_x = x_signed[11];
    wire neg_y = y_signed[11];
    wire [11:0] mag_x = neg_x ? (~x_signed + 12'd1) : x_signed;
    wire [11:0] mag_y = neg_y ? (~y_signed + 12'd1) : y_signed;
    
    //FSM
    localparam [3:0] 
        START       = 4'd0, 
        PRESSED     = 4'd1, 
        RELEASED    = 4'd2, 
        DONE        = 4'd3; 
    reg STATE = 0;
    reg HIT_BOUNDARY = 0;
    
    //Essential calculation regs/wires
    // Initial position
    localparam [9:0] px_init = 50;     // Start further right for visibility
    localparam [9:0] py_init = 50;    // Start near bottom
    
    reg [9:0] px = px_init, py = py_init;
    reg signed [15:0] vx = 0, vy = 0;
    
    // TUNE THESE VALUES until it FEELS right:
    localparam GRAVITY = 2;           // Pulls ball down
    localparam ACCEL_SENSITIVITY = 4; // How responsive to accelerometer  
    localparam VELOCITY_SCALE = 4;    // Controls shot power
    
    // y = py_init + vy * t - at*2
    // x = px_init + vx * t
    // v = v + a*t
    // x = x + v*t
    always @(posedge physics_clk)
    begin 
        if (rst)
        begin
            px = px_init; py = py_init;
            vx = 0; vy = 0;
        end
        
        //FSM 
        case(STATE)
            START:
            begin
                px = px_init; py = py_init;
                vx = 0; vy = 0;
                
                if (pressed_edge)
                begin
                    STATE = PRESSED;
                end
            end
            
            PRESSED:
            begin
                //Begin to Calculate velocity
                if(released)    //If released move onto next step
                begin
                    STATE = RELEASED;
                    //Reset Button Regs
                    btn_prev = 0;
                    pressed = 0;
                    pressed_edge = 0;
                    released = 0;
                end
                else
                begin
                    // Accumulate velocity
                    vx = vx + (mag_x[11:0] >>> ACCEL_SENSITIVITY);  //Logical Divide
                    vy = vy + (mag_y[11:0] >>> ACCEL_SENSITIVITY); 

                    STATE = PRESSED;
                end
                
            end
            
            
            RELEASED:
            begin
                // Calculate and decrease velocity over time due to gravity
                px = px + (vx >>> VELOCITY_SCALE);
                py = py + (vy >>> VELOCITY_SCALE);
                //Decrease Y velocity
                vy = vy - GRAVITY;             // Game-tuned gravity
                STATE = RELEASED;
                
                
// ##########        
// BORDERS
// ##########  
                
                //If hits floor or borders, decrease velocity
                
                // --------------          
                // X - Collisions
                // --------------
                
                // Left collision
//                if (px <= BALL_RADIUS) 
//                begin
//                    px <= BALL_RADIUS;
//                    vx <= -(vx >>> 1);  // Bounce - Momentum
                    
//                    if (vx > -4 && vx < 4)  //Check if contact makes Velocity slow enough to stop
//                    begin
//                        STATE <= DONE;
//                    end
//                end
//                //Right Condition
//                if (px >= (HD - 1) - BALL_RADIUS) 
//                begin
//                    px <= (HD - 1) - BALL_RADIUS;
//                    vx <= -(vx >>> 1);  // Bounce - Momentum
                    
//                    if (vx > -4 && vx < 4)  //Check if contact makes Velocity slow enough to stop
//                    begin
//                        STATE <= DONE;
//                    end
//                end   
                
//                // --------------          
//                // Y - Collisions
//                // --------------
                
//                // Floor collision
//                if (py <= BALL_RADIUS) 
//                begin
//                    py <= BALL_RADIUS;
//                    vy <= -(vy >>> 1);  // Bounce - Momentum
                    
//                    if (vy > -8 && vy < 8)  //Check if contact makes Velocity slow enough to stop
//                    begin
//                        STATE <= DONE;
//                    end
//                end
//                //Ceiling Condition
//                if (py >= (VD - 1) - BALL_RADIUS) 
//                begin
//                    py <= (VD - 1) - BALL_RADIUS;
//                    vy <= -(vy >>> 1);  // Bounce - Momentum
                    
//                    if (vy > -8 && vy < 8)  //Check if contact makes Velocity slow enough to stop
//                    begin
//                        STATE <= DONE;
//                    end
//                end 
                
// ####################        
// Basketball Hoop/Board
// ####################

                // --------------          
                // Backboard
                // --------------
                
                    
            end
                // END CASE
            
            DONE:
            begin
                px = px_init; py = py_init;
                vx = 0; vy = 0;
            
                STATE <= START;
            end
        
        
        default:
            STATE = START;
        
        endcase
        
    
    end
    
    
    
    // Assign Coordinates - Flip Y
    assign ball_x = (px <= BALL_RADIUS) ? BALL_RADIUS :
                    (px >= (HD - 1) - BALL_RADIUS) ? (HD - 1) - BALL_RADIUS :
                    px;
    
    assign ball_y = (py <= BALL_RADIUS) ? ((VD - 1) - BALL_RADIUS) :
                    (py >= (VD - 1) - BALL_RADIUS) ? ((VD - 1) - BALL_RADIUS) :
                    ((VD - 1) - py);

endmodule













