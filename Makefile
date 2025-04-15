.PHONY += clean sim

SRCS += 8bit.v
SRCS += 8bit_tb.v
SRCS += fetch.v
SRCS += decode.v
SRCS += execute.v
SRCS += writeback.v
SRCS += cache.v
SRCS += mem_if.v

eightbit:
	iverilog -g2012 ${SRCS} -o eightbit

8bit.vcd:
	vvp eightbit

sim:
	gtkwave 8bit.vcd

clean:
	rm 8bit.vcd eightbit
