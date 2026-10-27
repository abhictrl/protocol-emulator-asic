# Milestones

Checked items have evidence from a run. Anything not checked is not done, even if a later milestone's name appears in the roadmap.

## Milestone 1 — Fixed-function UART transmitter

| Item | Status | Evidence |
| --- | --- | --- |
| RTL: 4-state FSMD, 8-N-1, `CLKS_PER_BIT = 868` | done | [src/uart_tx.sv](../src/uart_tx.sv), [uart_tx.md](uart_tx.md) |
| Lint clean | done | `make lint`, 2026-10-27, Verilator 5.052 `-Wall` |
| Self-checking testbench | done | [tb/uart_tx_tb.sv](../tb/uart_tx_tb.sv), [verification.md](verification.md) |
| Simulation | done | `make verify`, 2026-10-27: 34 frames, 0 errors, `TEST PASSED` |
| Mutation check (bit order) | done | Scratch RTL only. `>> 1` changed to `<< 1` failed on frame `0xFF` bit 2, 2026-09-30 |
| Synthesis, area, timing | not yet | Milestone 4. No netlist, no cell count, no timing report |

## Milestone 2 — Reloadable I/O engine

Not started. No pin shell, instruction set, program counter, instruction memory, or assembler in this repo yet.

Exit criteria: a Tiny Tapeout pin shell (`clk`, `rst_n`, 8 inputs, 8 outputs, 8 bidirectional), a program the host loads and reloads after reset, an assembler, and one UART transmit program. The instruction set is general pin I/O. SPI and I2C land as programs after this engine simulates. Rules: [competition.md](competition.md).

## Milestone 3 — Assertions and stronger verification

Not started. The Milestone 1 bench is self-checking simulation, including a short random section. There are no SystemVerilog assertions and no formal proof.

## Milestone 4 — Tiny Tapeout 6x4 precheck

Not started. No Tiny Tapeout flow has been run. No GDS and no precheck result exist. Describe this design as simulated only.

The target is the CMOS5L flow on a 6x4 tile. Local hardening is the fallback when GitHub Actions hits the 6-hour limit. An IHP SRAM macro stays unused until the engine's memory does not fit in the tile. The 8x4 template is a later upgrade. Rules: [competition.md](competition.md).

## Submission

All open. Deadline 18 January 2027. The same list is in [competition.md](competition.md).

| Item | Status |
| --- | --- |
| Public repository | not yet |
| Passing Tiny Tapeout GDS precheck | not yet |
| Architecture and instruction-set doc | not yet |
| Assembler | not yet |
| UART, SPI, and I2C example programs | not yet |
| Verification write-up | not yet |
| AI-usage note | not yet |
| Pmod and external-parts notes | not yet |
