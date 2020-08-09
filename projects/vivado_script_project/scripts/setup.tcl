
proc setup_project { _git_root   _project_name _rundir         _fpga_part \
                     _board_part _file_list    _xip_properties _ip_interfaces \
                    _constraints} {

  puts "INFO \[project\] Creating a Vivado project"

  cd $_rundir
  create_project    $_project_name $_rundir/$_project_name -part $_fpga_part -force

  set_property      board_part         $_board_part [current_project]
  set_property      simulator_language "Verilog"    [current_project]

  add_verilog_files $_git_root $_file_list

  # Constraint files for the XIP which will be generated
  foreach _constraint [dict get $_constraints xip_timing] {
    if [string length $_constraint] {
      puts "INFO \[project\] Adding $_constraint XIP"
    }
  }

  foreach _constraint [dict get $_constraints xip_physical] {
    if [string length $_constraint] {
      puts "INFO \[project\] Adding $_constraint XIP"
    }
  }

  create_ip $_git_root $_rundir $_xip_properties $_ip_interfaces
}



proc add_verilog_files {_git_root _file_list} {


  puts "INFO \[project\] Reading file list ($_file_list)"
  # Reading the System Verilog files
  set _file_ref  [open $_file_list r]
  set _file_data [read $_file_ref]
  close $_file_ref

  puts "INFO \[project\] Parsing file list"
  # Parsing out the System Verilog file paths
  set _sv_files [split $_file_data "\n"]


  puts "INFO \[project\] Found ([llength $_sv_files]) files"

  variable _verilog_files

  foreach _row $_sv_files {
    if { ![regexp {^$} $_row] && ![regexp {^\s*#.*} $_row]} {
      append _verilog_files $_git_root/$_row " "
      puts "Read: $_git_root/$_row"
    }
  }

  read_verilog $_verilog_files

}


# ------------------------------------------------------------------------------
# Description:
#
# Packages a project into an Xilinx IP component.
#
# ------------------------------------------------------------------------------
#
# Documentation:
#
# - Arguments of "package_project";
#     Name            Description
#     ------------------------------------------
#     [-root_dir]     User specified root directory for component.xml
#     [-vendor]       User specified vendor of the IP VLNV
#     [-library]      User specified library of the IP VLNV
#     -taxonomy       User specified taxonomy for the IP
#     [-import_files] If true, import remote IP files into the IP structure.
#     [-set_current]  Set the core as the current core.
#     [-force]        Override existing packaged component.xml.
#
# ------------------------------------------------------------------------------
proc create_ip {_git_root _rundir _xip_properties _ip_interfaces} {

  puts "INFO \[ip_auto\] Creating IP"

  ipx::package_project    -root_dir "$_rundir/packed_ip" -taxonomy "/UserIP" -import_files -set_current false -force
  ipx::unload_core        $_rundir/packed_ip/component.xml
  ipx::edit_ip_in_project -upgrade true -name "tmp_edit_project" -directory "$_rundir/packed_ip" "$_rundir/packed_ip/component.xml"

  set_ip_properties    $_xip_properties
  set_ip_interfaces    $_ip_interfaces
  set_ip_clk_frequency [dict get $_ip_interfaces clocks]

  ipx::create_xgui_files [ipx::current_core]
  ipx::update_checksums  [ipx::current_core]
  ipx::save_core         [ipx::current_core]

  set_property core_revision 2                  [ipx::current_core]
  ipx::update_source_project_archive -component [ipx::current_core]
  ipx::create_xgui_files                        [ipx::current_core]
  ipx::update_checksums                         [ipx::current_core]
  ipx::save_core                                [ipx::current_core]
  ipx::move_temp_component_back -component      [ipx::current_core]
  close_project -delete
  #update_ip_catalog -rebuild -repo_path $_git_root
}



# ------------------------------------------------------------------------------
# Description:
#   Sets properties of new XIP's
# ------------------------------------------------------------------------------
#
# Documentation:
#
# - To see properties of an IP; report_property [ipx::current_core]
# ------------------------------------------------------------------------------
proc set_ip_properties {_xip_properties} {

  puts "INFO \[ip_auto\] Setting the IP's properties"

  set_property CORE_REVISION 2 [ipx::current_core]

  # Vendor
  if {[dict exists $_xip_properties ip_vendor]} {
    set_property VENDOR              [dict get $_xip_properties ip_vendor] [ipx::current_core]
    set_property VENDOR_DISPLAY_NAME [dict get $_xip_properties ip_vendor] [ipx::current_core]
  } else {
    puts "INFO \[ip_auto\] Property VENDOR not provided"
  }

  # Library
  if {[dict exists $_xip_properties ip_library]} {
    set_property LIBRARY      [dict get $_xip_properties ip_library]       [ipx::current_core]
  } else {
    puts "INFO \[ip_auto\] Property LIBRARY not provided"
  }

  # Name
  if {[dict exists $_xip_properties ip_name]} {
    set_property NAME         [dict get $_xip_properties ip_name]          [ipx::current_core]
  } else {
    puts "INFO \[ip_auto\] Property NAME not provided"
  }

  # Version
  if {[dict exists $_xip_properties ip_version]} {
    set_property VERSION      [dict get $_xip_properties ip_version]       [ipx::current_core]
  } else {
    puts "INFO \[ip_auto\] Property VERSION not provided"
  }

  # Display name
  if {[dict exists $_xip_properties ip_display_name]} {
    set_property DISPLAY_NAME [dict get $_xip_properties ip_display_name]  [ipx::current_core]
  } else {
    puts "INFO \[ip_auto\] Property DISPLAY_NAME not provided"
  }

  # Description
  if {[dict exists $_xip_properties ip_description]} {
    set_property DESCRIPTION  [dict get $_xip_properties ip_description]   [ipx::current_core]
  } else {
    puts "INFO \[ip_auto\] Property DESCRIPTION not provided"
  }

}


# ------------------------------------------------------------------------------
# Description:
#   Sets signal types of XIP ports
# ------------------------------------------------------------------------------
proc set_ip_interfaces {_ip_interfaces} {

  puts "INFO \[ip_auto\] Setting up the IP's clock interface(s)"
  foreach _clk [dict get $_ip_interfaces clocks] {
    ipx::infer_bus_interface [dict get $_clk name] xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
  }

  puts "INFO \[ip_auto\] Setting up the IP's reset interface(s)"
  foreach _rst [dict get $_ip_interfaces resets] {
    ipx::infer_bus_interface $_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

  }

  puts "INFO \[ip_auto\] Setting up the IP's data I/O interface(s)"
  foreach _io [dict get $_ip_interfaces data_io] {
    ipx::infer_bus_interface [dict get $_io name] xilinx.com:signal:data_rtl:1.0 [ipx::current_core]
  }

}


# ------------------------------------------------------------------------------
# Description:
#   Sets the clock frequency of all clocks in the argument list
# ------------------------------------------------------------------------------
proc set_ip_clk_frequency {_ip_clocks} {

  puts "INFO \[ip_auto\] Setting up the IP's ([llength $_ip_clocks]) clock frequency(s)"

  foreach _clk $_ip_clocks {
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces [dict get $_clk name] -of_objects [ipx::current_core]]
    set_property VALUE [dict get $_clk freq_hz] [ipx::get_bus_parameters -of_objects [ipx::get_bus_interfaces -of_objects [ipx::current_core] [dict get $_clk name] ] FREQ_HZ]
  }
}


# ------------------------------------------------------------------------------
# Description:
#   Creates a new block design and creates top I/O's and connects them
#   to the top module
# ------------------------------------------------------------------------------
proc create_block_design {_top_module_name _ip_interfaces} {

  puts "INFO \[project\] Creating block design"

  set _xip_vendor     [get_property VENDOR  [get_ips design_1_project_top_0_0]]
  set _xip_ip_library [get_property LIBRARY [get_ips design_1_project_top_0_0]]
  set _xip_ip_name    [get_property NAME    [get_ips design_1_project_top_0_0]]

  create_bd_design "design_1"

  create_bd_cell -type ip -vlnv $_xip_vendor:$_xip_ip_library:$_xip_ip_name:1.0 project_top_0
  create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} [get_bd_cells processing_system7_0]
  apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins project_top_0/clk]

  set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {[lindex [dict get $_ip_interfaces clocks]] 0}] [get_bd_cells processing_system7_0]

  # Create ports in the block design and connect them to the top module
  foreach _io [dict get $_ip_interfaces data_io] {
    create_bd_port -dir [dict get $_io dir] -type data [dict get $_io name]
    connect_bd_net [get_bd_pins /$_xip_ip_name/[dict get $_io name]] [get_bd_ports [dict get $_io name]]
  }

  connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
}



set _git_root             [exec git rev-parse --show-toplevel]

set _project_name         "vivado_script_project"
set _project_path         $_git_root/projects/$_project_name
set _rundir               $_project_path/rundir

set _file_list            $_project_path/scripts/synth_file_list.lst
set _fpga_part            "xc7z020clg400-1"
set _board_part           "digilentinc.com:arty-z7-20:part0:1.0"
set _top_module_name      "project_top"

set _xip_timing_constraints   "$_project_path/constraints/timing_constraints.tcl"
set _xip_physical_constraints ""
set _top_timing_constraints   ""
set _top_physical_constraints "$_project_path/constraints/physical_constraints.tcl"

set _constraints [dict create                   \
  xip_timing   [list $_xip_timing_constraints   \
               ]                                \
  xip_physical [list $_xip_physical_constraints \
               ]                                \
  top_timing   [list $_top_timing_constraints   \
               ]                                \
  top_physical [list $_top_physical_constraints \
               ]                                \
]


set _xip_properties [dict create \
  ip_vendor       "aerland.se" \
  ip_library      "aerland_ip_lib" \
  ip_name         "project_top" \
  ip_version      "1.0" \
  ip_display_name "project_top" \
  ip_description  "ip_testing" \
]

set _ip_interfaces [dict create                          \
  clocks  [list [dict create name clk freq_hz 125000000] \
          ]                                              \
  resets  [list rst_n                                    \
          ]                                              \
  data_io [list [dict create name "led_0" dir "O"]       \
                [dict create name "led_1" dir "O"]       \
                [dict create name "led_2" dir "O"]       \
                [dict create name "led_3" dir "O"]       \
                [dict create name "btn_0" dir "I"]       \
                [dict create name "btn_1" dir "I"]       \
                [dict create name "btn_2" dir "I"]       \
                [dict create name "btn_3" dir "I"]       \
          ]                                              \
]


setup_project $_git_root $_project_name $_rundir $_fpga_part $_board_part $_file_list $_xip_properties $_ip_interfaces $_constraints




# proc generate_output_products {_project_path _project_name} {

#   puts "INFO \[project\] Generating output products"

#   generate_target all [get_files $_project_path/$_project_name/$_project_name.srcs/sources_1/bd/design_1/design_1.bd]

#   catch { config_ip_cache -export [get_ips -all design_1_project_top_0_0] }
#   catch { config_ip_cache -export [get_ips -all design_1_processing_system7_0_0] }
#   catch { config_ip_cache -export [get_ips -all design_1_rst_ps7_0_125M_0] }

#   export_ip_user_files -of_objects [get_files $_project_path/$_project_name/$_project_name.srcs/sources_1/bd/design_1/design_1.bd] -no_script -sync -force -quiet

#   create_ip_run [get_files -of_objects [get_fileset sources_1] $_project_path/$_project_name/$_project_name.srcs/sources_1/bd/design_1/design_1.bd]

#   launch_runs -jobs 12 {design_1_project_top_0_0_synth_1 design_1_processing_system7_0_0_synth_1 design_1_rst_ps7_0_125M_0_synth_1}

#   export_simulation -of_objects          [get_files $_project_path/$_project_name/$_project_name.srcs/sources_1/bd/design_1/design_1.bd] \
#                     -directory           $_project_path/$_project_name/$_project_name.ip_user_files/sim_scripts \
#                     -ip_user_files_dir   $_project_path/$_project_name/$_project_name.ip_user_files \
#                     -ipstatic_source_dir $_project_path/$_project_name/$_project_name.ip_user_files/ipstatic \
#                     -lib_map_path        [list {modelsim=$_project_path/$_project_name/$_project_name.cache/compile_simlib/modelsim} \
#                                                {questa=$_project_path/$_project_name/$_project_name.cache/compile_simlib/questa} \
#                                                {ies=$_project_path/$_project_name/$_project_name.cache/compile_simlib/ies} \n
#                                                {xcelium=$_project_path/$_project_name/$_project_name.cache/compile_simlib/xcelium} \
#                                                {vcs=$_project_path/$_project_name/$_project_name.cache/compile_simlib/vcs} \
#                                                {riviera=$_project_path/$_project_name/$_project_name.cache/compile_simlib/riviera}] \
#                     -use_ip_compiled_libs -force -quiet
# }



# proc create_wrapper {_project_path _project_name} {

#   puts "INFO \[project\] Create wrapper and synthesize"

#   make_wrapper -files [get_files $_project_path/$_project_name/$_project_name.srcs/sources_1/bd/design_1/design_1.bd] -top
#   add_files -norecurse $_project_path/$_project_name/$_project_name.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
#   set_property top design_1_wrapper [current_fileset]
#   update_compile_order -fileset sources_1
# }


# launch_runs synth_1 -jobs 12
# launch_runs impl_1  -jobs 12

# write_hw_platform -fixed -force  -include_bit -file $_project_path/$_project_name/design_1_wrapper.xsa




# proc regenerate_output_products {} {
#   reset_target all [get_files  $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd]
#   export_ip_user_files -of_objects  [get_files  $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd] -sync -no_script -force -quiet
#   delete_ip_run [get_files -of_objects [get_fileset sources_1] $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd]
#   generate_target all [get_files  $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd]
#   catch { config_ip_cache -export [get_ips -all design_1_project_top_0_0] }
#   catch { config_ip_cache -export [get_ips -all design_1_processing_system7_0_0] }
#   catch { config_ip_cache -export [get_ips -all design_1_rst_ps7_0_125M_0] }
#   export_ip_user_files -of_objects [get_files $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd] -no_script -sync -force -quiet
#   create_ip_run [get_files -of_objects [get_fileset sources_1] $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd]
#   export_simulation -of_objects [get_files $_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd] -directory $_project_path/arty_z7_blink_led/arty_z7_blink_led.ip_user_files/sim_scripts -ip_user_files_dir $_project_path/arty_z7_blink_led/arty_z7_blink_led.ip_user_files -ipstatic_source_dir $_project_path/arty_z7_blink_led/arty_z7_blink_led.ip_user_files/ipstatic -lib_map_path [list {modelsim=$_project_path/arty_z7_blink_led/arty_z7_blink_led.cache/compile_simlib/modelsim} {questa=$_project_path/arty_z7_blink_led/arty_z7_blink_led.cache/compile_simlib/questa} {ies=$_project_path/arty_z7_blink_led/arty_z7_blink_led.cache/compile_simlib/ies} {xcelium=$_project_path/arty_z7_blink_led/arty_z7_blink_led.cache/compile_simlib/xcelium} {vcs=$_project_path/arty_z7_blink_led/arty_z7_blink_led.cache/compile_simlib/vcs} {riviera=$_project_path/arty_z7_blink_led/arty_z7_blink_led.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
# }

# proc export_hardware {} {
#   set_property pfm_name {} [get_files -all {$_project_path/arty_z7_blink_led/arty_z7_blink_led.srcs/sources_1/bd/design_1/design_1.bd}]
#   write_hw_platform -fixed -include_bit -force -file $_project_path/arty_z7_blink_led/design_1_wrapper.xsa
# }



# set base_dir [get_property DIRECTORY [current_project]]
# set prj_name [get_property NAME [current_project]]

# # Reset BD
# reset_target all [get_files -filter {IS_GENERATED == 0} *.bd]

# # Delete IP files
# exec rm -Rf $base_dir/${prj_name}.srcs/sources_1/ipshared
# exec rm -Rf $base_dir/${prj_name}.ip_user_files

# # Reset IP instances
# reset_target all [get_files  $base_dir/${prj_name}.srcs/sources_1/ip/*.xci]
# export_ip_user_files -of_objects  [get_files  $base_dir/${prj_name}.srcs/sources_1/ip/*.xci] -sync -no_script -force -quiet

# # Generate targets
# generate_target all [get_files -filter {IS_GENERATED == 0} *.bd]
# generate_target all [get_files  $base_dir/${prj_name}.srcs/sources_1/ip/*.xci]

# # Update ip catalog
# update_ip_catalog -rebuild
