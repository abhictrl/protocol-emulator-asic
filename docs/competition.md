# Competition constraints

Organizer rules for the Jane Street protocol-emulator ASIC competition, from the October 2026 update. This page records those rules. It is not a claim about simulated RTL. Status and evidence stay in [milestones.md](milestones.md).

Submissions close 18 January 2027. The organizers aim to announce the selected designs in early February, ahead of the March 2027 CMOS5L shuttle. About four designs are planned for tapeout. Winners receive the chip mounted on the latest Tiny Tapeout ETR demo board.

## Area

Design to a 6x4 tile budget. The planned maximum is 8x4. That size is an upgrade for after Tiny Tapeout publishes the CMOS5L 8x4 template. The October 2026 update still had that template unpublished.

## Pins

The Tiny Tapeout digital shell is the pin model for later milestones:

| Port | Count | Role |
| --- | --- | --- |
| `clk` | 1 | Clock |
| `rst_n` | 1 | Active-low reset |
| inputs | 8 | Dedicated inputs |
| outputs | 8 | Dedicated outputs |
| bidirectional | 8 | Input, output, or both, with an output enable |

There are no analog pads. Analog or mixed-signal circuits inside the tile, such as a PLL, are allowed when they pass precheck. Demo-board I/O is 3.3 V.

I2C uses the bidirectional pins. Pull-ups, transceivers, level shifters, and any other off-chip parts go on a Pmod. Document whatever the design needs.

CMOS5L pad drive and delay numbers are unpublished. Tiny Tapeout is checking the similar SG13G2 process for figures.

- [Pmods and the ETR demo board](https://tinytapeout.com/specs/pcb-etr/)
- [Pinouts](https://tinytapeout.com/specs/pinouts/)

## Clock

The competition sets no target frequency. The chip clock is whatever closes timing after place-and-route and still meets the protocols in use.

The Milestone 1 bench stays at 100 MHz, with `CLKS_PER_BIT = 868` for 115200 baud. See [uart_tx.md](uart_tx.md). That clock is the current simulation choice.

Protocol targets, with no fixed speed requirement beyond these common settings:

| Protocol | Target |
| --- | --- |
| UART | Common baud rates, including 115200 |
| SPI | Modes 0–3 |
| I2C | 100 kHz and 400 kHz |

## Reset and program load

The design uses `rst_n` to reach a known state. On an ASIC, flops do not power up at 0. On the demo board, reset comes from a button or from software. The Milestone 1 transmitter already uses `rst_n`.

Deselecting the design powers it down and drops its state. The host reloads the program when the design is selected again. The microcontroller on the demo board is the host. Another host is fine when the load sequence is documented.

How the program is loaded is part of the design. Milestone 2 includes that path: a host load, and a reload after reset.

[Moving from FPGA to ASIC](https://tinytapeout.com/hdl/fpga_vs_asic/)

## Protocols

Demonstrate UART, SPI, and I2C on the programmable engine. Controller role comes first. A target role, and running more than one protocol at a time, are bonuses.

The instruction set is general pin I/O (pin read and write, timed waits, branches) so a protocol the engine was not built around can still be a new program. UART transmission is the first program. SPI modes 0–3 and I2C at 100 kHz and 400 kHz are example programs after that engine simulates, and before the design is treated as submittable.

Low-speed USB and 10 Mbit Ethernet are stretch goals for after a passing 6x4 precheck. They count for more when the chip itself does the line coding, CRC, and clock recovery.

## SRAM

IHP SRAM macros are allowed, including more than one, when they fit in the tiles and pass the Tiny Tapeout precheck. Add a macro when the engine's memory does not fit in the tile. Until then the macro stays unused.

[Adding an IHP SRAM macro to a CMOS5L tile](https://kdp1965.github.io/ihp-um-janestreet-prism/ihp_sram_macro.html)

## Judging

Flexibility is the main criterion: the finished chip can be reprogrammed to support a protocol it was not designed for. Judges also look at which protocols are demonstrated, what the architecture makes possible, and how the design was built and verified. There is no fixed weighting. A design with fewer protocols can still compete when the architecture and the verification are strong.

The entry includes the software side: an assembler or toolchain (or a bitstream flow) and example programs for the protocols on the chip.

AI tools are allowed. The write-up describes how they were used.

## Submission

A public repository containing:

- RTL and tests
- A passing GDS precheck from the Tiny Tapeout flow
- Documentation of the architecture and the instruction set
- An assembler or toolchain, with example programs
- A verification write-up
- A note on how AI tools were used
- Notes for any Pmod or other external parts

A video or demo is optional. The repository can stay private until submission. The competition entry is its own open-source CMOS5L submission.

Use the Tiny Tapeout flow. That is how winning designs go onto the shuttle. GitHub Actions has a 6 hour limit. If a run hits that limit, run the same flow locally: [local hardening](https://tinytapeout.com/guides/local-hardening/). The CMOS5L install failure in the Tiny Tapeout GDS action was fixed; rerun with the latest action if an older run hit it.

The checklist below is open. Nothing on it is done.

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
