# Protocol Emulator ASIC
#
# Verilator (this machine):
#   make lint
#   make sim
#
# Xilinx XSIM (Vivado), equivalent:
#   xvlog -sv src/uart_tx.sv tb/uart_tx_tb.sv
#   xelab uart_tx_tb -timescale 1ns/1ps
#   xsim  uart_tx_tb -R
#
# Optional VCD from either flow:
#   make sim DUMP_VCD=1
#   xvlog -sv -d DUMP_VCD src/uart_tx.sv tb/uart_tx_tb.sv
#
# Docs (WaveDrom JSON -> committed SVG):
#   make docs
#   make verify

VERILATOR ?= verilator
TOP       ?= uart_tx_tb
SRC       := src/uart_tx.sv
TB        := tb/uart_tx_tb.sv
WAVEDROM  ?= npx --yes wavedrom-cli

WD_JSON   := $(wildcard docs/wavedrom/*.json)
WD_SVG    := $(patsubst docs/wavedrom/%.json,docs/img/%.svg,$(WD_JSON))

VERILATOR_FLAGS := --binary --timing -Wall --timescale 1ns/1ps --top-module $(TOP)

ifeq ($(DUMP_VCD),1)
VERILATOR_FLAGS += -DDUMP_VCD --trace
endif

.PHONY: lint sim verify docs clean

lint:
	$(VERILATOR) --lint-only -Wall $(SRC)

sim:
	$(VERILATOR) $(VERILATOR_FLAGS) $(SRC) $(TB)
	./obj_dir/V$(TOP)

verify: lint sim

docs: $(WD_SVG)

docs/img/%.svg: docs/wavedrom/%.json
	mkdir -p docs/img
	$(WAVEDROM) -i $< -s $@

clean:
	rm -rf obj_dir
