// Simple button debouncer (synchronizes + waits for stability)
// Author(s): Benjamin T
// Adjust CNT_WIDTH for how long a press must be stable (~1-5 ms good).
module debounce_btn #(
  parameter CNT_WIDTH = 18  // ~2.6 ms @ 100 MHz
)(
  input  wire clk,
  input  wire btn_in,
  output reg  btn_db
);
  reg sync0, sync1;
  reg [CNT_WIDTH:0] cnt;
  wire same = (btn_db == sync1);

  always @(posedge clk) begin
    // 2FF synchronizer
    sync0 <= btn_in;
    sync1 <= sync0;

    if (same) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1'b1;
      if (&cnt) btn_db <= sync1; // update when stable long enough
    end
  end
endmodule