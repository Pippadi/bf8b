.PHONY += clean sim

SRC_DIR := src
TARGET_DIR := target

SRCS += $(SRC_DIR)/bf8b.v
SRCS += $(SRC_DIR)/bf8b_tb.v
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

bf8b:
	mkdir -p $(TARGET_DIR)
	iverilog -g2012 ${SRCS} -o $(TARGET_DIR)/bf8b

bf8b.vcd:
	vvp $(TARGET_DIR)/bf8b

sim:
	gtkwave $(TARGET_DIR)/bf8b.vcd

clean:
	rm -r $(TARGET_DIR)
