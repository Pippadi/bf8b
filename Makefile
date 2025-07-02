.PHONY += clean sim

SRC_DIR := src
TARGET_DIR := target

SRCS += $(SRC_DIR)/bf8b.v
SRCS += $(SRC_DIR)/bf8b_tb.v
SRCS += $(SRC_DIR)/fetch.v
SRCS += $(SRC_DIR)/decode.v
SRCS += $(SRC_DIR)/alu.v
SRCS += $(SRC_DIR)/execute.v
SRCS += $(SRC_DIR)/writeback.v
SRCS += $(SRC_DIR)/en_shift_reg.v
SRCS += $(SRC_DIR)/cache.v
SRCS += $(SRC_DIR)/mem_if.v

bf8b:
	mkdir -p $(TARGET_DIR)
	iverilog -g2012 ${SRCS} -o $(TARGET_DIR)/bf8b

bf8b.vcd:
	vvp $(TARGET_DIR)/bf8b

sim:
	gtkwave $(TARGET_DIR)/bf8b.vcd

clean:
	rm -r $(TARGET_DIR)
