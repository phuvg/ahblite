# Guide :
#	"make compile" : compiles RTL code.
#	"make sim" : run simulation.
#	"make view" : invoke waveform.

#-----------------------------------------------------------------------------
#Source code directory
RTL_DIR = ../../rtl
TB_DIR = ../../tb
TEST = tb_ahblite_interconnect_1m1s.sv
#-----------------------------------------------------------------------------
#RTL code
RTL_SRC = $(RTL_DIR)/*.sv
#-----------------------------------------------------------------------------
#TB code
TB_SRC = $(TB_DIR)/$(TEST)
#-----------------------------------------------------------------------------
#Tools
COMPILER = vlog
SIMULATOR = vsim
#-----------------------------------------------------------------------------
#Tool options, compile and simulate flags
COFLAGS = -f
SFLAGS = -c\
	 -l report.log\
	 -voptargs="+acc"\
	 -do "run -all" work.tb_ahblite_interconnect_1m1s
#-t ns\
#-----------------------------------------------------------------------------
#Tool output


#-----------------------------------------------------------------------------
#PHONY
.PHONY : compile sim view clean
#-----------------------------------------------------------------------------
#MAKE DIRECTIVES
compile: $(TB_SRC) $(RTL_SRC)
	vlib work
	vmap work work
	$(COMPILER) $(TB_SRC) $(RTL_SRC)

sim:
	$(SIMULATOR) $(SFLAGS)
	vcd2wlf wf_ahblite_interconnect_1m1s.vcd wf_ahblite_interconnect_1m1s.wlf	
view:
	vsim -i -view wf_ahblite_interconnect_1m1s.wlf &
clean: 
	rm -rf wf_ahblite_interconnect_1m1s.vcd \
	wf_ahblite_interconnect_1m1s.wlf \
	report.log \
	work
