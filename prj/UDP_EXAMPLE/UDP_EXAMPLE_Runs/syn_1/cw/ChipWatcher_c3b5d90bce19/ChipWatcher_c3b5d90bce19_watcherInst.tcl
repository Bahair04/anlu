source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_c3b5d90bce19
set bus_num              4
set depth                4096
set ram_len              19
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   0
set trig_bus_num         4
set trig_bus_din_num     19
set trig_bus_ctrl_len    64
set trig_ctrl_len        84
set trig_bus_width       { 16,1,1,1 };
set trig_bus_din_pos     { 0,16,17,18 };
set trig_bus_ctrl_pos    { 0,52,56,60 };
set bus_size             {  1 1 1 16 }
set data_enable          { probe0 probe1 probe2 probe3 }
set trig_enable          { probe0 probe1 probe2 probe3 }
set fp [open "cw/ChipWatcher_c3b5d90bce19/ChipWatcher_c3b5d90bce19_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
