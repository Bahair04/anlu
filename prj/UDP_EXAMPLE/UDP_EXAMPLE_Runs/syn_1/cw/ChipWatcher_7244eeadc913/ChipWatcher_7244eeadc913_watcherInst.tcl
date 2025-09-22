source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_7244eeadc913
set bus_num              4
set depth                1024
set ram_len              34
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   0
set trig_bus_num         4
set trig_bus_din_num     34
set trig_bus_ctrl_len    112
set trig_ctrl_len        132
set trig_bus_width       { 1,1,16,16 };
set trig_bus_din_pos     { 0,1,2,18 };
set trig_bus_ctrl_pos    { 0,4,8,60 };
set bus_size             {  16 16 1 1 }
set data_enable          { probe0 probe1 probe2 probe3 }
set trig_enable          { probe0 probe1 probe2 probe3 }
set fp [open "cw/ChipWatcher_7244eeadc913/ChipWatcher_7244eeadc913_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
