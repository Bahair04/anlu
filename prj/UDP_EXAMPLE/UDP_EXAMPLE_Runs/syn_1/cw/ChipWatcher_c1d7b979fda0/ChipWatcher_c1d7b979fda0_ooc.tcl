import_device eagle_s20.db -package EG4S20BG256
set_param flow ooc_flow on
read_verilog -file "ChipWatcher_c1d7b979fda0_watcherInst.sv"
optimize_rtl
map_macro
map
pack
report_area -file ChipWatcher_c1d7b979fda0_gate.area
export_db -mode ooc "ChipWatcher_c1d7b979fda0_ooc.db"
