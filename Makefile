.PHONY += clean sim

SRC_DIR := src
TARGET_DIR := target

SRCS += $(SRC_DIR)/bf8b.v
SRCS += $(SRC_DIR)/bf8b_tb.sv
SRCS += $(SRC_DIR)/fetch.sv
SRCS += $(SRC_DIR)/decode.sv
SRCS += $(SRC_DIR)/execute/adder.sv
SRCS += $(SRC_DIR)/execute/alu.sv
SRCS += $(SRC_DIR)/execute/execute.sv
SRCS += $(SRC_DIR)/writeback.sv
SRCS += $(SRC_DIR)/cache/en_shift_reg.sv
SRCS += $(SRC_DIR)/cache/prio_enable.sv
SRCS += $(SRC_DIR)/cache/cache.sv
SRCS += $(SRC_DIR)/mem_if/mem_mux.sv
SRCS += $(SRC_DIR)/mem_if/mem_if.sv

bf8b:
	mkdir -p $(TARGET_DIR)
	iverilog -g2012 ${SRCS} -o $(TARGET_DIR)/bf8b

bf8b.vcd:
	vvp $(TARGET_DIR)/bf8b

sim:
	gtkwave $(TARGET_DIR)/bf8b.vcd

clean:
	rm -r $(TARGET_DIR)
