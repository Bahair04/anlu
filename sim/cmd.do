## part 1: create lib
vlib work
vmap work work

## part 2: load rtl
vlog -timescale 1ps/1ps -f  compile.f                                                                     
                                                       
## part 3: sim
vsim -L D:/modeltech64_10.7/anlogic/EG4S -gui -voptargs=+acc work.tb_udp_fdma_ddr

#vsim -voptargs=+acc work.fdma_ddr_test_tb                              

## part 4: add wave
#do wave.do

## part 5: show ui
view wave
view structure
view signals

## part 6: run sim
#run -all



