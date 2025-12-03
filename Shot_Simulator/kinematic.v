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

module kinematic (
    input  wire        clk,
    input  wire        rst,
    input  wire        BTN,
    input  wire [15:0] ax_raw, ay_raw,     // signed raw
    input  wire [15:0] ax_flick, ay_flick, // unsigned magnitude
    output wire [9:0]  ball_x, ball_y
);

    // 60 Hz physics clock
    reg [20:0] physics_counter = 0;
    wire physics_clk = (physics_counter == 21'd1_666_666);
    
    always @(posedge clk) begin
        physics_counter <= physics_counter + 1;
        if (physics_counter == 21'd1_666_666)
            physics_counter <= 0;
    end
    
    // button edges in physics domain
    reg btn_prev = 0;
    reg pressed_edge = 0;
    reg released_edge = 0;
    
    always @(posedge physics_clk) begin
        btn_prev      <= BTN;
        pressed_edge  <= (BTN && !btn_prev);
        released_edge <= (!BTN && btn_prev);
    end

    // screen / physics geometry
    localparam BALL_RADIUS = 4;
    localparam HD = 640;
    localparam VD = 480;

    // hoop/backboard geometry (screen space) from basketballHoop
    localparam integer BOARD_X_L = 630;
    localparam integer BOARD_X_R = 633;
    localparam integer BOARD_Y_T = 200;
    localparam integer BOARD_Y_B = 260;

    localparam integer HOOP_X_L  = 610;
    localparam integer HOOP_X_R  = 630;
    localparam integer HOOP_Y_T  = 254;
    localparam integer HOOP_Y_B  = 258;

    // convert board/hoop Y ranges to internal py coordinates
    localparam integer BOARD_PY_MIN = (VD-1) - BOARD_Y_B; // 479-260 = 219
    localparam integer BOARD_PY_MAX = (VD-1) - BOARD_Y_T; // 479-200 = 279
    localparam integer HOOP_PY_MIN  = (VD-1) - HOOP_Y_B;  // 479-258 = 221
    localparam integer HOOP_PY_MAX  = (VD-1) - HOOP_Y_T;  // 479-254 = 225

    // rim edge precision
    localparam integer RIM_EDGE_WIDTH = 3;
    localparam integer RIM_TOP_PY     = (HOOP_PY_MIN + HOOP_PY_MAX) / 2;
    localparam integer RIM_THICKNESS  = 2;

    // bounce factor: roughly 0.75 * v
    localparam integer BOUNCE_NUM   = 3;
    localparam integer BOUNCE_SHIFT = 2;

    // FSM
    localparam [3:0] 
        START    = 4'd0, 
        PRESSED  = 4'd1, 
        RELEASED = 4'd2, 
        DONE     = 4'd3;

    reg [3:0] STATE = START;
    
    // position and velocity
    localparam [9:0] px_init = 150;
    localparam [9:0] py_init = 80;
    
    reg [9:0] px = px_init, py = py_init;
    reg signed [15:0] vx = 0, vy = 0;
    
    // physics parameters
    localparam GRAVITY           = 4;
    localparam ACCEL_SENSITIVITY = 4;
    localparam VELOCITY_SCALE    = 4;
    
    wire signed [11:0] x_signed = ax_raw[11:0];      // keeps direction
    wire signed [11:0] y_signed = ay_raw[11:0];

    wire [11:0] mag_x = ax_flick[11:0];              // magnitude only
    wire [11:0] mag_y = ay_flick[11:0];

    // FSM
    always @(posedge physics_clk) begin 
        if (rst) begin
            px      <= px_init; 
            py      <= py_init;
            vx      <= 0; 
            vy      <= 0;
            STATE   <= START;
        end
        else begin
            case (STATE)
                START: begin
                    px      <= px_init; 
                    py      <= py_init;
                    vx      <= 0; 
                    vy      <= 0;
                    
                    if (pressed_edge) begin
                        STATE <= PRESSED;
                    end
                    else begin
                        STATE <= START;
                    end
                end
                
                PRESSED: begin
                    if (released_edge) begin
                        STATE <= RELEASED;
                    end
                    else begin
                        // X: use sign of raw, magnitude from flick
                        if (x_signed[11])
                            vx <= vx + (mag_x >>> ACCEL_SENSITIVITY);
                        else
                            vx <= vx - (mag_x >>> ACCEL_SENSITIVITY);

                        // Y: smaller vertical increment (note +1 shift)
                        if (y_signed[11])
                            vy <= vy - (mag_y >>> (ACCEL_SENSITIVITY + 1));
                        else
                            vy <= vy + (mag_y >>> (ACCEL_SENSITIVITY + 1));

                        STATE <= PRESSED;
                    end
                end

            RELEASED: begin
                // update position
                px <= px + (vx >>> VELOCITY_SCALE);
                py <= py + (vy >>> VELOCITY_SCALE);
                
                // gravity
                vy <= vy - GRAVITY;

                // backboard collision (vertical plane)
                if ((vx > 0) &&
                    (px + BALL_RADIUS >= BOARD_X_L) &&
                    (px + BALL_RADIUS <= BOARD_X_R + 2) &&
                    (py >= BOARD_PY_MIN) &&
                    (py <= BOARD_PY_MAX)) begin
                    vx <= -((vx * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                    px <= BOARD_X_L - BALL_RADIUS - 1;
                end

                // rim left edge side collision
                if ((vx > 0) &&
                    (px + BALL_RADIUS >= HOOP_X_L) &&
                    (px + BALL_RADIUS <= HOOP_X_L + RIM_EDGE_WIDTH) &&
                    (py >= HOOP_PY_MIN) &&
                    (py <= HOOP_PY_MAX)) begin
                    vx <= -((vx * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                    px <= HOOP_X_L - BALL_RADIUS - 1;
                end

                // rim right edge side collision
                if ((vx < 0) &&
                    (px - BALL_RADIUS <= HOOP_X_R) &&
                    (px - BALL_RADIUS >= HOOP_X_R - RIM_EDGE_WIDTH) &&
                    (py >= HOOP_PY_MIN) &&
                    (py <= HOOP_PY_MAX)) begin
                    vx <= -((vx * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                    px <= HOOP_X_R + BALL_RADIUS + 1;
                end

                // rim left top "cap" (tiny thickness above left edge)
                if ((vy < 0) &&
                    ((py - BALL_RADIUS) <= (RIM_TOP_PY + 4)) &&
                    ((py - BALL_RADIUS) >= (RIM_TOP_PY - 1)) &&
                    (px + BALL_RADIUS >= HOOP_X_L) &&
                    (px + BALL_RADIUS <= HOOP_X_L + RIM_EDGE_WIDTH)) begin
                    vy <= -((vy * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                    py <= RIM_TOP_PY + BALL_RADIUS + 1;
                end

                // rim right top "cap" (tiny thickness above right edge)
                if ((vy < 0) &&
                    ((py - BALL_RADIUS) <= (RIM_TOP_PY + RIM_THICKNESS/2)) &&
                    ((py - BALL_RADIUS) >= (RIM_TOP_PY - RIM_THICKNESS/2)) &&
                    (px - BALL_RADIUS <= HOOP_X_R) &&
                    (px - BALL_RADIUS >= HOOP_X_R - RIM_EDGE_WIDTH)) begin
                    vy <= -((vy * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                    py <= RIM_TOP_PY + BALL_RADIUS + 1;
                end

                // default in-play state
                STATE <= RELEASED;
                
                // Check if NEXT position will be out of bounds (not in floor zone)
                if (px > HD + BALL_RADIUS || py > VD + BALL_RADIUS) begin
                        STATE <= DONE;
                    end
                    
                // ground collision    
               else if ((vy < 0) && (py <= BALL_RADIUS + 3)) begin
                    vy <= -((vy * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                    py <= BALL_RADIUS + 1;
                end
            end


                DONE: begin
                    px      <= px_init; 
                    py      <= py_init;
                    vx      <= 0; 
                    vy      <= 0;
                    STATE   <= START;
                end
        
                default: begin
                    STATE <= START;
                end
            endcase
        end
    end
    
    // coordinates for VGA (flip Y)
    assign ball_x = (px <= BALL_RADIUS) ? BALL_RADIUS :
                    (px >= (HD - 1) - BALL_RADIUS) ? (HD - 1) - BALL_RADIUS :
                    px;
    
    assign ball_y = (py <= BALL_RADIUS) ? ((VD - 1) - BALL_RADIUS) :
                    (py >= (VD - 1) - BALL_RADIUS) ? ((VD - 1) - BALL_RADIUS) :
                    ((VD - 1) - py);

endmodule
