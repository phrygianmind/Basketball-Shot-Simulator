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
    input  wire        clk,
    input  wire        rst,
    input  wire        BTN,
    input  wire [15:0] ax, ay,
    output wire [9:0]  ball_x, ball_y,
    output wire [3:0]  LED
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
    
    reg [3:0] LEDhold = 4'b0000;
    assign LED = LEDhold;
    
    // position and velocity
    localparam [9:0] px_init = 50;
    localparam [9:0] py_init = 50;
    
    reg [9:0] px = px_init, py = py_init;
    reg signed [15:0] vx = 0, vy = 0;
    
    // physics parameters
    localparam GRAVITY           = 4;
    localparam ACCEL_SENSITIVITY = 4;
    localparam VELOCITY_SCALE    = 5;
    
    // signed 12-bit values and magnitudes
    wire signed [11:0] x_signed = ax[11:0];
    wire signed [11:0] y_signed = ay[11:0];
    wire neg_x = x_signed[11];
    wire neg_y = y_signed[11];
    wire [11:0] mag_x = neg_x ? (~x_signed + 12'd1) : x_signed;
    wire [11:0] mag_y = neg_y ? (~y_signed + 12'd1) : y_signed;
    
    // FSM
    always @(posedge physics_clk) begin 
        if (rst) begin
            px      <= px_init; 
            py      <= py_init;
            vx      <= 0; 
            vy      <= 0;
            STATE   <= START;
            LEDhold <= 4'b0000;
        end
        else begin
            case (STATE)
                START: begin
                    px      <= px_init; 
                    py      <= py_init;
                    vx      <= 0; 
                    vy      <= 0;
                    LEDhold <= 4'b0001;
                    
                    if (pressed_edge) begin
                        STATE   <= PRESSED;
                        LEDhold <= 4'b0010;
                    end
                    else begin
                        STATE <= START;
                    end
                end
                
                PRESSED: begin
                    LEDhold <= 4'b0010;
                    
                    if (released_edge) begin
                        STATE   <= RELEASED;
                        LEDhold <= 4'b0100;
                    end
                    else begin
                        vx    <= vx + (mag_x >>> ACCEL_SENSITIVITY);
                        vy    <= vy + (mag_y >>> ACCEL_SENSITIVITY + 1); 
                        STATE <= PRESSED;
                    end
                end
                
                RELEASED: begin
                    // update position
                    px <= px + (vx >>> VELOCITY_SCALE);
                    py <= py + (vy >>> VELOCITY_SCALE);
                    
                    // gravity (vy < 0 means falling in this coordinate system)
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

                    // rim left edge collision
                    if ((vx > 0) &&
                        (px + BALL_RADIUS >= HOOP_X_L) &&
                        (px + BALL_RADIUS <= HOOP_X_L + RIM_EDGE_WIDTH) &&
                        (py >= HOOP_PY_MIN) &&
                        (py <= HOOP_PY_MAX)) begin
                        vx <= -((vx * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                        px <= HOOP_X_L - BALL_RADIUS - 1;
                    end

                    // rim right edge collision
                    if ((vx < 0) &&
                        (px - BALL_RADIUS <= HOOP_X_R) &&
                        (px - BALL_RADIUS >= HOOP_X_R - RIM_EDGE_WIDTH) &&
                        (py >= HOOP_PY_MIN) &&
                        (py <= HOOP_PY_MAX)) begin
                        vx <= -((vx * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                        px <= HOOP_X_R + BALL_RADIUS + 1;
                    end

                    // rim top collision (thin horizontal band; center open)
                    if ((vy < 0) &&
                        ((py - BALL_RADIUS) <= (RIM_TOP_PY + RIM_THICKNESS/2)) &&
                        ((py - BALL_RADIUS) >= (RIM_TOP_PY - RIM_THICKNESS/2)) &&
                        (px >= (HOOP_X_L + RIM_EDGE_WIDTH)) &&
                        (px <= (HOOP_X_R - RIM_EDGE_WIDTH))) begin
                        vy <= -((vy * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                        py <= RIM_TOP_PY + BALL_RADIUS + 1;
                    end

                    // default in-play state
                    LEDhold <= 4'b0100;
                    STATE   <= RELEASED;
                    
                    // floor collision at bottom of screen (priority)
                    if ((vy < 0) && (py <= BALL_RADIUS + 1)) begin
                        vy <= -((vy * BOUNCE_NUM) >>> BOUNCE_SHIFT);
                        py <= BALL_RADIUS + 1;
                    end
                    // only if NOT a floor hit this tick, allow reset
                    else if (px > HD || py > VD) begin
                        STATE   <= DONE;
                        LEDhold <= 4'b1000;
                    end
                    
                end

                DONE: begin
                    px      <= px_init; 
                    py      <= py_init;
                    vx      <= 0; 
                    vy      <= 0;
                    STATE   <= START;
                    LEDhold <= 4'b0001;
                end
        
                default: begin
                    STATE   <= START;
                    LEDhold <= 4'b1111;
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
