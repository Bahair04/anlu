source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_7244eeadc913
set bus_num              11
set depth                1024
set ram_len              113
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   0
set trig_bus_num         11
set trig_bus_din_num     113
set trig_bus_ctrl_len    374
set trig_ctrl_len        394
set trig_bus_width       { 16,1,1,10,25,8,2,25,16,1,8 };
set trig_bus_din_pos     { 0,16,17,18,28,53,61,63,88,104,105 };
set trig_bus_ctrl_pos    { 0,52,56,60,94,173,201,211,290,342,346 };
set bus_size             {  8 1 16 25 2 8 25 10 1 1 16 }
set data_enable          { probe0 probe1 probe2 probe3 probe4 probe5 probe6 probe7 probe8 probe9 probe10 }
set trig_enable          { probe0 probe1 probe2 probe3 probe4 probe5 probe6 probe7 probe8 probe9 probe10 }
set fp [open "cw/ChipWatcher_7244eeadc913/ChipWatcher_7244eeadc913_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
