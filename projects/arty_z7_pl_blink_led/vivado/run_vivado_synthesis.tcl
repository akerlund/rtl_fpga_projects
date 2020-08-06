# Project variables
set git_root        [exec git rev-parse --show-toplevel]
set project_path    "$git_root/projects/arty_z7_pl_blink_led/vivado"
set file_list_path  "$project_path/synth_file_list.lst"

# Synthesis settings
set top_module_name      "project_top"
set fpga_part            "xc7z020clg400-1"
set defines              ""
set inc_dirs             ""
set mode                 "default"
set timing_constraints   "$project_path/timing_constraints.tcl"
set physical_constraints "$project_path/arty_z7_20_master.xdc"

source $git_root/scripts/vivado_synth_module.tcl
