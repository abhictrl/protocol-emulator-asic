`timescale 1ns/1ps

// uart_tx_tb.sv
// Self-checking testbench for the Milestone 1 UART transmitter.
//
// Stimulus is driven on negedge clk; DUT outputs are sampled on negedge clk.
// The DUT itself samples on posedge, so this split avoids simulator races.
//
// Golden 8-N-1 frame (LSB first on the wire):
//   {stop, data[7:0], start} = {1'b1, data, 1'b0}
//   bit 0 = start (0), bits 1..8 = data[0]..data[7], bit 9 = stop (1)
// Each bit is held for CLKS_PER_BIT clocks. A frame is therefore 10*868 = 8680
// clocks, after which tx must be 1 and tx_busy must be 0.
//
// Note: tx_start is level-sensitive in IDLE. Holding it high would launch a
// new frame as soon as the previous one finishes. This bench always uses a
// 1-cycle pulse, matching the module comment.
//
// Optional waveform: compile with +define+DUMP_VCD (or -DDUMP_VCD).

module uart_tx_tb;

    localparam int CLKS_PER_BIT = 868;
    localparam int BITS_PER_FRM = 10;
    localparam int CLKS_PER_FRM = BITS_PER_FRM * CLKS_PER_BIT;  // 8680
    localparam int RAND_SEED    = 32'hC0FFEE01;

    logic       clk;
    logic       rst_n;
    logic       tx_start;
    logic [7:0] tx_data_in;
    logic       tx;
    logic       tx_busy;

    int unsigned errors;
    int unsigned frames_checked;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_start  (tx_start),
        .tx_data_in(tx_data_in),
        .tx        (tx),
        .tx_busy   (tx_busy)
    );

    // 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        #(20ms);
        $fatal(1, "Watchdog timeout at %0t — DUT likely stuck", $time);
    end

`ifdef DUMP_VCD
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);
    end
`endif

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    // Called at a negedge. Does not consume time.
    task automatic check(
        input logic  actual,
        input logic  expected,
        input string what
    );
        if (actual !== expected) begin
            errors++;
            if (errors <= 40) begin
                $display("ERROR @%0t: %s  got=%0b expected=%0b",
                         $time, what, actual, expected);
            end else if (errors == 41) begin
                $display("ERROR: further mismatch prints suppressed");
            end
            if (errors >= 200) begin
                $fatal(1, "Too many errors, aborting");
            end
        end
    endtask

    task automatic check_idle(input string what);
        check(tx,      1'b1, {what, " tx"});
        check(tx_busy, 1'b0, {what, " tx_busy"});
    endtask

    // Drive a 1-cycle tx_start pulse. Must be called at a negedge while idle.
    // Returns at the first negedge of the START bit (frame is live, tx_start=0).
    task automatic pulse_start(input logic [7:0] data);
        tx_data_in = data;
        tx_start   = 1'b1;
        @(negedge clk);
        tx_start   = 1'b0;
    endtask

    // Sample all 8680 clocks of a live frame. Must be called at the first
    // START-bit negedge. Returns at the first idle negedge after the stop bit.
    //
    // inject_noise:
    //   scramble tx_data_in every cycle, and pulse tx_start once in START,
    //   once mid-DATA, and once in STOP. None of that may change the frame.
    task automatic check_frame(
        input logic [7:0] data,
        input logic       inject_noise
    );
        logic [9:0] exp_frame;
        logic       exp_bit;
        string      tag;

        exp_frame = {1'b1, data, 1'b0};

        for (int bit_i = 0; bit_i < BITS_PER_FRM; bit_i++) begin
            exp_bit = exp_frame[bit_i];
            for (int c = 0; c < CLKS_PER_BIT; c++) begin
                if ((bit_i != 0) || (c != 0)) begin
                    @(negedge clk);
                end

                if (inject_noise) begin
                    tx_data_in = 8'($urandom);
                    tx_start   = ((bit_i == 0) && (c == CLKS_PER_BIT / 4))
                              || ((bit_i == 4) && (c == CLKS_PER_BIT / 2))
                              || ((bit_i == 9) && (c == CLKS_PER_BIT / 4));
                end

                $sformat(tag, "frame 0x%02h bit %0d clk %0d", data, bit_i, c);
                check(tx,      exp_bit, {tag, " tx"});
                check(tx_busy, 1'b1,    {tag, " tx_busy"});
            end
        end

        if (inject_noise) begin
            tx_start   = 1'b0;
            tx_data_in = 8'h00;
        end

        @(negedge clk);
        check_idle($sformatf("after 0x%02h", data));
        frames_checked++;
    endtask

    // Full send: pulse start, then check the wire every clock.
    // Call at a negedge while the DUT is idle. Returns at the idle negedge
    // after the frame, so the next call can start on that same edge. The FSM
    // still spends one clock in IDLE between frames, because tx_start is
    // accepted only there. This task does not insert an extra gap.
    task automatic send_and_check(
        input logic [7:0] data,
        input logic       inject_noise
    );
        $display("  send 0x%02h%s", data, inject_noise ? " (noise on inputs)" : "");
        pulse_start(data);
        check_frame(data, inject_noise);

        if (inject_noise) begin
            for (int i = 0; i < (2 * CLKS_PER_BIT); i++) begin
                @(negedge clk);
                check_idle("post-noise idle");
            end
        end
    endtask

    task automatic wait_n_clocks(input int n);
        repeat (n) @(negedge clk);
    endtask

    // ---------------------------------------------------------------------
    // Tests
    // ---------------------------------------------------------------------

    initial begin : tests
        int unsigned rng_seed;

        errors         = 0;
        frames_checked = 0;
        rst_n          = 1'b0;
        tx_start       = 1'b0;
        tx_data_in     = 8'h00;

        $timeformat(-9, 0, " ns", 12);
        rng_seed = RAND_SEED;
        void'($urandom(rng_seed));

        $display("==============================================");
        $display(" uart_tx self-check  CLKS_PER_BIT=%0d", CLKS_PER_BIT);
        $display(" one bit = %0d clocks, one frame = %0d clocks",
                 CLKS_PER_BIT, CLKS_PER_FRM);
        $display("==============================================");

        // ----------------------------------------------------------------
        // 1. Reset and idle
        // ----------------------------------------------------------------
        $display("[1] reset and idle");
        wait_n_clocks(4);
        rst_n = 1'b1;
        wait_n_clocks(2);
        check_idle("just out of reset");

        for (int i = 0; i < 2000; i++) begin
            @(negedge clk);
            check_idle("idle hold");
        end

        // ----------------------------------------------------------------
        // 2. Directed bytes
        // ----------------------------------------------------------------
        $display("[2] directed bytes");
        send_and_check(8'h00, 1'b0);
        send_and_check(8'hFF, 1'b0);
        send_and_check(8'h55, 1'b0);
        send_and_check(8'hAA, 1'b0);
        send_and_check(8'h01, 1'b0);  // only LSB set — first data bit
        send_and_check(8'h80, 1'b0);  // only MSB set — last data bit
        send_and_check(8'hA5, 1'b0);

        // ----------------------------------------------------------------
        // 3. Back-to-back frames (no extra gap inserted between calls)
        // ----------------------------------------------------------------
        $display("[3] back-to-back frames");
        send_and_check(8'h12, 1'b0);
        send_and_check(8'h34, 1'b0);
        send_and_check(8'h56, 1'b0);
        send_and_check(8'h78, 1'b0);
        send_and_check(8'h9A, 1'b0);

        // ----------------------------------------------------------------
        // 4. tx_start ignored while busy; data captured once
        // ----------------------------------------------------------------
        $display("[4] ignore tx_start / tx_data_in while busy");
        send_and_check(8'hC3, 1'b1);

        // ----------------------------------------------------------------
        // 5. Asynchronous reset mid-frame
        // ----------------------------------------------------------------
        $display("[5] async reset mid-frame");
        pulse_start(8'h96);

        // 3.5 bit times from the start of the frame, then leave the clock
        // edge: 3 ns after a posedge is still in the high phase (period 10 ns).
        repeat ((3 * CLKS_PER_BIT) + (CLKS_PER_BIT / 2)) @(posedge clk);
        #3;
        rst_n = 1'b0;
        #1;  // still between edges — if the DUT only reset on posedge, this fails
        check_idle("async reset");

        @(negedge clk);
        rst_n = 1'b1;
        for (int i = 0; i < 100; i++) begin
            @(negedge clk);
            check_idle("after mid-frame reset");
        end

        send_and_check(8'h3C, 1'b0);

        // ----------------------------------------------------------------
        // 6. Constrained-random bytes, random 0..50 cycle gaps
        // ----------------------------------------------------------------
        $display("[6] 20 random frames");
        for (int i = 0; i < 20; i++) begin
            send_and_check(8'($urandom), 1'b0);
            wait_n_clocks($urandom_range(0, 50));
        end

        $display("==============================================");
        $display(" frames checked: %0d", frames_checked);
        $display(" errors:         %0d", errors);
        if (errors == 0) begin
            $display(" TEST PASSED");
            $display("==============================================");
            $finish;
        end else begin
            $display(" TEST FAILED");
            $display("==============================================");
            $fatal(1, "TEST FAILED with %0d error(s)", errors);
        end
    end

endmodule
