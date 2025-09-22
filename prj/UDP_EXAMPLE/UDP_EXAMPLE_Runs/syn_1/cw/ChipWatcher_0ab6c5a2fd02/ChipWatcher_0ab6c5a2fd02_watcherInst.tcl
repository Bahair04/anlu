source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_0ab6c5a2fd02
set bus_num              3
set depth                4096
set ram_len              25
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   0
set trig_bus_num         3
set trig_bus_din_num     25
set trig_bus_ctrl_len    84
set trig_ctrl_len        104
set trig_bus_width       { 16,8,1 };
set trig_bus_din_pos     { 0,16,24 };
set trig_bus_ctrl_pos    { 0,52,80 };
set bus_size             {  1 8 16 }
set data_enable          { probe0 probe1 probe2 }
set trig_enable          { probe0 probe1 probe2 }
set fp [open "cw/ChipWatcher_0ab6c5a2fd02/ChipWatcher_0ab6c5a2fd02_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
