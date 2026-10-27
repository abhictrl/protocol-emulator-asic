// uart_tx.sv
// Fixed-function UART transmitter (Milestone 1).
//
// Protocol:  8-N-1  (1 start bit, 8 data bits LSB-first, 1 stop bit, no parity)
// Clock:     100 MHz
// Baud:      115200
//
// Baud math:
//   CLKS_PER_BIT = round(100e6 / 115200) = 868
//   Actual baud  = 100e6 / 868 ≈ 115207.4  (0.0064%, 64 ppm).
//   A typical UART link tolerates on the order of 2% total baud error.
//   One bit      = 868 clocks
//   One frame    = 10 bits × 868 = 8680 clocks
//
// Frame on `tx` (idle line is high):
//   START: 0 for 868 clocks
//   DATA:  d0, d1, ..., d7  (each 868 clocks; LSB first)
//   STOP:  1 for 868 clocks
//
// Handshake:
//   Pulse `tx_start` for one cycle while IDLE. The byte on `tx_data_in` is
//   captured on that clock edge. `tx_busy` and the start bit appear on the
//   *next* cycle because the state register updates on the clock.
//   `tx_start` is ignored while busy.
//
// Architecture: FSMD with four states (IDLE, START, DATA, STOP).
// Two procedural blocks:
//   always_ff  — state + datapath registers
//   always_comb — next-state logic + Moore outputs
//
// `tx` and `tx_busy` are a combinational decode of the registered state
// (Moore outputs), in a separate always_comb from the always_ff registers.
// START is 2'b01 and DATA is 2'b10, so that transition flips both state bits.
// If the first data bit is 0, skew between those bits can glitch `tx` high
// at the edge. STOP (2'b11) to IDLE (2'b00) can pass through START and glitch
// `tx` low. A UART samples near the middle of the 8.68 µs bit, so the glitch
// sits far from the sample point. Registering `tx` is the cleanup before this
// pin is used on a chip. It is not done here: the bench is cycle-accurate to
// this Moore timing.

module uart_tx #(
    parameter int CLKS_PER_BIT = 868
) (
    input  logic       clk,
    input  logic       rst_n,       // asynchronous, active-low
    input  logic       tx_start,    // 1-cycle pulse; honored only in IDLE
    input  logic [7:0] tx_data_in,
    output logic       tx,
    output logic       tx_busy
);

    // 868 needs 10 bits (0..867). $clog2 keeps the width correct if the
    // parameter is changed for a different clock or baud.
    localparam int CNT_W   = $clog2(CLKS_PER_BIT);
    localparam int CNT_MAX = CLKS_PER_BIT - 1;

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t            state, state_next;
    logic [CNT_W-1:0]  clk_cnt;     // clocks elapsed in the current bit
    logic [2:0]        bit_idx;     // which data bit is on the wire (0..7)
    logic [7:0]        shift_reg;   // remaining bits; LSB is the live data bit
    logic              bit_done;    // 1 when this bit has used all CLKS_PER_BIT clocks

    assign bit_done = (clk_cnt == CNT_MAX[CNT_W-1:0]);

    // -------------------------------------------------------------------------
    // Sequential: state and datapath.
    // Async reset so the line comes up idle (tx high) even before clocks.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_cnt   <= '0;
            bit_idx   <= '0;
            shift_reg <= '0;
        end else begin
            state <= state_next;

            // Baud counter is NOT free-running. It counts only while a bit is
            // being serialized, and it restarts at 0:
            //   - while IDLE (nothing to time)
            //   - on a state change (new bit: start, first data, or stop)
            //   - when bit_done (next data bit in DATA, same state)
            if ((state == IDLE) || (state_next != state) || bit_done) begin
                clk_cnt <= '0;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end

            // Capture the byte once, at the IDLE -> START request. The shift
            // register then owns the frame; later changes on tx_data_in cannot
            // corrupt it. Shift right after each data bit so [0] is always
            // the next LSB to send.
            if ((state == IDLE) && tx_start) begin
                shift_reg <= tx_data_in;
                bit_idx   <= 3'd0;
            end else if ((state == DATA) && bit_done) begin
                shift_reg <= shift_reg >> 1;
                bit_idx   <= bit_idx + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Combinational: next-state + Moore outputs.
    // Assign defaults first so every path writes state_next, tx, and tx_busy
    // (no inferred latches). The default case recovers from X or a bad encoding.
    // -------------------------------------------------------------------------
    always_comb begin
        state_next = state;
        tx         = 1'b1;   // UART idle / stop level
        tx_busy    = 1'b1;

        case (state)
            IDLE: begin
                tx      = 1'b1;
                tx_busy = 1'b0;
                if (tx_start) begin
                    state_next = START;
                end
            end
            START: begin
                tx      = 1'b0;   // start bit is low
                tx_busy = 1'b1;
                if (bit_done) begin
                    state_next = DATA;
                end
            end
            DATA: begin
                tx      = shift_reg[0];
                tx_busy = 1'b1;
                if (bit_done && (bit_idx == 3'd7)) begin
                    state_next = STOP;
                end
            end
            STOP: begin
                tx      = 1'b1;   // stop bit is high
                tx_busy = 1'b1;
                if (bit_done) begin
                    state_next = IDLE;
                end
            end
            default: begin
                state_next = IDLE;
                tx         = 1'b1;
                tx_busy    = 1'b0;
            end
        endcase
    end

endmodule
