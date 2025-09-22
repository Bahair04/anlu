source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_c1d7b979fda0
set bus_num              6
set depth                16384
set ram_len              19
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   0
set trig_bus_num         6
set trig_bus_din_num     19
set trig_bus_ctrl_len    72
set trig_ctrl_len        92
set trig_bus_width       { 5,6,5,1,1,1 };
set trig_bus_din_pos     { 0,5,11,16,17,18 };
set trig_bus_ctrl_pos    { 0,19,41,60,64,68 };
set bus_size             {  1 1 1 5 6 5 }
set data_enable          { probe0 probe1 probe2 probe3 probe4 probe5 }
set trig_enable          { probe0 probe1 probe2 probe3 probe4 probe5 }
set fp [open "cw/ChipWatcher_c1d7b979fda0/ChipWatcher_c1d7b979fda0_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
