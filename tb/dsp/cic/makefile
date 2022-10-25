all:clean compile debug
collect:clean compile simulate
.PHONY:compile debug stimulus clean 

MODELSIM_HOME = D:/usr/questasim64_2020.1/win64
AHB_FRBM_CONV_HOME = ../../infrastructure/commerical/cmsdk_ahb_fileread_masters/bin/fm2conv.pl

STIMULUS_IN = stimulus_cic_dec.fri
STIMULUS_OUT = stimulus_cic_dec.m2d

OUTPUT = work
TESTBENCH = agc_linear_tb_intf
WAVE_CONFIG = wave.do
FILELIST = filelist.f

compile:
	${MODELSIM_HOME}/vlib ${OUTPUT}
	${MODELSIM_HOME}/vmap ${OUTPUT}
	${MODELSIM_HOME}/vlog -f ${FILELIST}
debug:
	${MODELSIM_HOME}/vsim -voptargs=+acc ${OUTPUT}.${TESTBENCH} -do "${WAVE_CONFIG}"
simulate:
	${MODELSIM_HOME}/vsim -voptargs=+acc ${OUTPUT}.${TESTBENCH} -do "run -all"
stimulus:
	perl ${AHB_FRBM_CONV_HOME} -busWidth 32 -infile ${STIMULUS_IN} -outfile ${STIMULUS_OUT}
clean:
	rm -rf work *.wlf *.mti *.mpf transcript