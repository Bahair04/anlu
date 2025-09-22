import_device eagle_s20.db -package EG4S20BG256
set_param flow ooc_flow on
read_verilog -file "ChipWatcher_c3b5d90bce19_watcherInst.sv"
optimize_rtl
map_macro
map
pack
report_area -file ChipWatcher_c3b5d90bce19_gate.area
export_db -mode ooc "ChipWatcher_c3b5d90bce19_ooc.db"
