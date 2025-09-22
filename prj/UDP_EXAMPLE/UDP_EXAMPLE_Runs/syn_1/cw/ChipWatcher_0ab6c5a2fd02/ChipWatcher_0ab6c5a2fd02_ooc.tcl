import_device eagle_s20.db -package EG4S20BG256
set_param flow ooc_flow on
read_verilog -file "ChipWatcher_0ab6c5a2fd02_watcherInst.sv"
optimize_rtl
map_macro
map
pack
report_area -file ChipWatcher_0ab6c5a2fd02_gate.area
export_db -mode ooc "ChipWatcher_0ab6c5a2fd02_ooc.db"
