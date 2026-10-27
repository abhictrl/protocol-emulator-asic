# Documentation

Design notes, diagrams, and verification evidence for the protocol emulator. The [roadmap](../readme.md) is the short version. This directory is the place that has to stay true to the code.

## Index

| Doc | What it covers |
| --- | --- |
| [uart_tx.md](uart_tx.md) | Milestone 1 transmitter: interface, baud math, FSM, datapath, timing |
| [verification.md](verification.md) | Self-checking testbench, how to run it, last passing result |
| [milestones.md](milestones.md) | Checklist and evidence. Items are checked only after a passing run |
| [competition.md](competition.md) | Organizer rules: area, pins, clock, protocols, submission. Not a claim about the RTL |

## Diagrams

Two kinds, on purpose:

- **Mermaid** in the markdown files for state machines, datapaths, and flows. GitHub renders these directly. There is no separate source file.
- **WaveDrom** for timing. Edit the JSON in [wavedrom/](wavedrom/), then run `make docs`. That writes SVG into [img/](img/). Commit both the JSON and the SVG so the pictures show up without extra tools.

Do not hand-edit the SVG files. The next `make docs` overwrites them.

## Verify first, then update the docs

A behavior claim in these files is allowed only after the code that implements it has passed in the same session:

```sh
make verify    # lint, then the self-checking simulation
```

If that fails, leave the docs alone and fix the code. If it passes, update the diagram or table that changed, re-run `make docs` when a waveform changed, and refresh the "Last verified" block in [verification.md](verification.md) plus the checklist in [milestones.md](milestones.md).

Work that has not been simulated is labeled **not yet verified**. The Tiny Tapeout precheck, area, and timing closure are Milestone 4 and are not claimed here. [competition.md](competition.md) records organizer rules and is not a behavior claim.
