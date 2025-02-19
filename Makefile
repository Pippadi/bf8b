.PHONY += clean sim

eightbit:
	iverilog -g2012 8bit.v 8bit_tb.v fetch.v decode.v execute.v writeback.v -o eightbit

8bit.vcd:
	vvp eightbit

sim:
	gtkwave 8bit.vcd

clean:
	rm 8bit.vcd eightbit
