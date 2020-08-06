if { ![info exists project_path]    ||
     ![info exists file_list_path]  ||
     ![info exists top_module_name] ||
     ![info exists fpga_part]
} {
  puts "ERROR \[project\] Missing variable(s)"
  return 0
}

puts "I', OK"

# Paths for reports and run
set  report_dir "$project_path/reports"
set  rundir     "$project_path/rundir"
file mkdir $report_dir
file mkdir $rundir
cd $rundir

################################################################################
puts "Reading the design"
################################################################################

# Reading the System Verilog files
set file_ref  [open $file_list_path r]
set file_data [read $file_ref]
close $file_ref

# Parsing out the System Verilog file paths
set sv_files [split $file_data "\n"]

foreach row $sv_files {
  if { ![regexp {^$} $row] && ![regexp {^\s*#.*} $row]} {
    puts $git_root/$row
    read_verilog $git_root/$row
  }
}

################################################################################
# Synthesis
################################################################################

read_xdc $timing_constraints
read_xdc $physical_constraints

synth_design -top $top_module_name -part $fpga_part -verilog_define $defines -include_dirs $inc_dirs -mode $mode

write_checkpoint      -force $report_dir/post_synth.dcp
report_timing_summary -file  $report_dir/post_synth_timing_summary.rpt
report_utilization    -file  $report_dir/post_synth_util.rpt

################################################################################
# Logic Optimization
################################################################################

opt_design
place_design
report_clock_utilization -file $report_dir/clock_util.rpt

if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
  puts "INFO \[timing\] Found setup timing violations, running physical optimization"
  phys_opt_design
}

write_checkpoint      -force $report_dir/post_place.dcp
report_utilization    -file  $report_dir/post_place_util.rpt
report_timing_summary -file  $report_dir/post_place_timing_summary.rpt

################################################################################
# Implementation
################################################################################

route_design
write_checkpoint      -force $report_dir/post_route.dcp
report_route_status   -file  $report_dir/post_route_status.rpt
report_timing_summary -file  $report_dir/post_route_timing_summary.rpt
report_drc            -file  $report_dir/post_imp_drc.rpt

write_bitstream -force $top_module_name.bit