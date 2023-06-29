
all: compile elaborate simulate

.PHONY: compile
.PHONY: elaborate
.PHONY: simulate

OUTFILTER=grep --color=always -e "ERROR.*" -e "CRIT.*" -e "WARN.*" 


compile: src/*.v FORCE
	@ printf "xvlog $(XVLOG_OPTIONS) src/*.v\n"
	@! xvlog $(XVLOG_OPTIONS) src/*.v | $(OUTFILTER)

elaborate: compile
	@ printf "xelab -debug typical -s sim testbench\n"
	@! xelab -debug typical -s sim top | $(OUTFILTER)

simulate: elaborate
	@ printf "xsim --runall sim\n"
	@ xsim --runall sim


gui: elaborate 
	xsim --gui sim

irun:
	irun src/*.v

implement:
	vivado -mode batch -source build.tcl

check: 
	vivado -mode batch -source check_syntax.tcl 


FORCE:

clean:
	@rm -f *.jou
	@rm -f *.log
	@rm -f *.history
	@rm -Rf INCA_libs
	@rm -Rf xsim.dir
	@rm -f *.pb
	@rm -f *.wdb
	@rm -f *.pb
	@rm -f *.rpt
	@rm -f post_*
	@rm -f *_webtalk.*
	@rm -Rf .Xil
	@rm -f *.bit
	@rm -f *~
	@rm -f src/*~

