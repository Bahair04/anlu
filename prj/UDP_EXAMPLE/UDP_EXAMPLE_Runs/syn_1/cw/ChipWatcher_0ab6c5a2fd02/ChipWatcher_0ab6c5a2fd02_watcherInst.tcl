source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_0ab6c5a2fd02
set bus_num              4
set depth                2048
set ram_len              49
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   0
set trig_bus_num         4
set trig_bus_din_num     49
set trig_bus_ctrl_len    160
set trig_ctrl_len        180
set trig_bus_width       { 1,12,12,24 };
set trig_bus_din_pos     { 0,1,13,25 };
set trig_bus_ctrl_pos    { 0,4,44,84 };
set bus_size             {  24 12 12 1 }
set data_enable          { probe0 probe1 probe2 probe3 }
set trig_enable          { probe0 probe1 probe2 probe3 }
set fp [open "cw/ChipWatcher_0ab6c5a2fd02/ChipWatcher_0ab6c5a2fd02_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
