.PHONY += clean sim

PROJ = bf8b

SRC_DIR := src

SRCS += $(SRC_DIR)/bf8b.v
SRCS += $(SRC_DIR)/fetch.v
SRCS += $(SRC_DIR)/decode.v
SRCS += $(SRC_DIR)/execute/adder.v
SRCS += $(SRC_DIR)/execute/alu.v
SRCS += $(SRC_DIR)/execute/execute.v
SRCS += $(SRC_DIR)/writeback.v
SRCS += $(SRC_DIR)/cache/en_shift_reg.v
SRCS += $(SRC_DIR)/cache/prio_enable.v
SRCS += $(SRC_DIR)/cache/cache.v
SRCS += $(SRC_DIR)/mem_if/mem_mux.v
SRCS += $(SRC_DIR)/mem_if/mem_if.v
SRCS += $(SRC_DIR)/uart/clockgen.v
SRCS += $(SRC_DIR)/uart/tx_manager.v
SRCS += $(SRC_DIR)/uart/tx_ser.v
SRCS += $(SRC_DIR)/uart/rx_manager.v
SRCS += $(SRC_DIR)/uart/rx_deser.v
SRCS += $(SRC_DIR)/uart/fifo.v
SRCS += $(SRC_DIR)/uart/uart.v
TB_TOP = $(SRC_DIR)/bf8b_tb.v
OC_TOP = $(SRC_DIR)/orangecrab_top.v
OC_PLL_FILENAME = pll.v

OC_VERSION=r0.2.1
OC_PCF_FILE=../orangecrab-examples/verilog/orangecrab_${OC_VERSION}.pcf
NEXTPNR_DENSITY=--25k

all: $(PROJ).dfu

vcd: $(PROJ).vcd

%.vcd:
	iverilog -g2012 ${SRCS} $(TB_TOP) -o $(PROJ)
	vvp $(PROJ)

sim: $(PROJ).vcd
	gtkwave $<

dfu: ${PROJ}.dfu
	dfu-util --alt 0 -D $<

%.json:
	ecppll -i 48 -o 20 -f $(OC_PLL_FILENAME)
	yosys -p "read_verilog ${SRCS} $(OC_PLL_FILENAME) $(OC_TOP); synth_ecp5 -json $@"

%_out.config: %.json
	nextpnr-ecp5 --json $< --textcfg $@ $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(OC_PCF_FILE)

%.bit: %_out.config
	ecppack --compress --freq 38.8 --input $< --bit $@

%.dfu : %.bit
	cp -a $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

clean:
	rm -f ${PROJ}.bit ${PROJ}_out.config ${PROJ}.json ${PROJ}.dfu $(PROJ) $(PROJ).vcd $(OC_PLL_FILENAME)
