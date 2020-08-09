
proc setup_project { _git_root   _project_name  _rundir         _fpga_part \
                     _board_part _file_list     _xip_properties _ip_interfaces \
                    _constraints _fclk_freq_mhz _bd_design_name } {

  puts "INFO \[project\] Creating a Vivado project"

  create_project    $_project_name $_rundir/$_project_name -part $_fpga_part -force

  set_property      board_part         $_board_part [current_project]
  set_property      simulator_language "Verilog"    [current_project]

  add_verilog_files $_git_root $_file_list

  # Constraint files for the XIP which will be generated
  foreach _constraint [dict get $_constraints xip_timing] {
    if [string length $_constraint] {
      puts "INFO \[project\] Adding IP constraint ($_constraint)"
      add_files -fileset constrs_1 -norecurse $_constraint
      set_property used_in_implementation false [get_files $_constraint]
      set_property used_in_simulation     false [get_files $_constraint]
    }
  }

  foreach _constraint [dict get $_constraints xip_physical] {
    if [string length $_constraint] {
      puts "INFO \[project\] Adding IP constraint ($_constraint)"
      add_files -fileset constrs_1 -norecurse $_constraint
      set_property used_in_implementation false [get_files $_constraint]
      set_property used_in_simulation     false [get_files $_constraint]
    }
  }

  create_ip $_git_root $_rundir $_xip_properties $_ip_interfaces

  create_block_design $_xip_properties $_ip_interfaces $_fclk_freq_mhz $_bd_design_name

  create_wrapper $_rundir $_project_name $_bd_design_name

  generate_output_products $_rundir $_project_name $_bd_design_name

  # Constraint files for the XIP which will be generated
  foreach _constraint [dict get $_constraints top_timing] {
    if [string length $_constraint] {
      puts "INFO \[project\] Adding TOP constraint ($_constraint)"
      add_files -fileset constrs_1 -norecurse $_constraint
      set_property used_in_synthesis  false [get_files $_constraint]
      set_property used_in_simulation false [get_files $_constraint]
    }
  }

  foreach _constraint [dict get $_constraints top_physical] {
    if [string length $_constraint] {
      puts "INFO \[project\] Adding TOP constraint ($_constraint)"
      add_files -fileset constrs_1 -norecurse $_constraint
      set_property used_in_synthesis  false [get_files $_constraint]
      set_property used_in_simulation false [get_files $_constraint]
    }
  }

  launch_runs impl_1 -to_step write_bitstream -jobs 12
  wait_on_run impl_1 -quiet

  export_hardware $_rundir $_project_name $_bd_design_name

  close_project
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

  set_property previous_version_for_upgrade user.org:user:project_top:1.0 [ipx::current_core]
  set_property core_revision 1 [ipx::current_core]

  ipx::create_xgui_files [ipx::current_core]
  ipx::update_checksums  [ipx::current_core]
  ipx::save_core         [ipx::current_core]

  ipx::move_temp_component_back -component [ipx::current_core]
  close_project -delete

  set_property ip_repo_paths $_rundir/packed_ip [current_project]
  update_ip_catalog
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
proc create_block_design {_xip_properties _ip_interfaces _fclk_freq_mhz _bd_design_name} {

  puts "INFO \[project\] Creating block design"

  set _xip_vendor     [dict get $_xip_properties ip_vendor]
  set _xip_ip_library [dict get $_xip_properties ip_library]
  set _xip_ip_name    [dict get $_xip_properties ip_name]
  set _bd_name        bd_${_xip_ip_name}_0


  create_bd_design $_bd_design_name
  create_bd_cell -type ip -vlnv $_xip_vendor:$_xip_ip_library:$_xip_ip_name:1.0 $_bd_name
  create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} [get_bd_cells processing_system7_0]
  apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins $_bd_name/clk]


  set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ $_fclk_freq_mhz] [get_bd_cells processing_system7_0]

  # Create ports in the block design and connect them to the top module
  foreach _io [dict get $_ip_interfaces data_io] {
    create_bd_port -dir [dict get $_io dir] -type data [dict get $_io name]
    connect_bd_net [get_bd_pins /$_bd_name/[dict get $_io name]] [get_bd_ports [dict get $_io name]]
  }

  connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]

  validate_bd_design
  save_bd_design
}



proc create_wrapper {_rundir _project_name _bd_design_name} {

  puts "INFO \[project\] Create wrapper and synthesize"

  make_wrapper -files    [get_files $_rundir/$_project_name/$_project_name.srcs/sources_1/bd/$_bd_design_name/$_bd_design_name.bd] -top
  add_files    -norecurse $_rundir/$_project_name/$_project_name.srcs/sources_1/bd/$_bd_design_name/hdl/${_bd_design_name}_wrapper.v
  set_property top ${_bd_design_name}_wrapper [current_fileset]
}



proc generate_output_products {_rundir _project_name _bd_design_name} {

  puts "INFO \[project\] Generating output products"

  generate_target      all         [get_files $_rundir/$_project_name/$_project_name.srcs/sources_1/bd/$_bd_design_name/$_bd_design_name.bd]
  export_ip_user_files -of_objects [get_files $_rundir/$_project_name/$_project_name.srcs/sources_1/bd/$_bd_design_name/$_bd_design_name.bd] -no_script -sync -force -quiet
}



proc export_hardware {_rundir _project_name _bd_design_name} {

  puts "INFO \[project\] Exporting hardware as .xsa file"

  set_property pfm_name {} [get_files -all $_rundir/$_project_name/$_project_name.srcs/sources_1/bd/$_bd_design_name/$_bd_design_name.bd]
  write_hw_platform -fixed -include_bit -force -file $_rundir/$_project_name/${_bd_design_name}_wrapper.xsa
}


set _git_root             [exec git rev-parse --show-toplevel]

set _project_name         "vivado_script_project"
set _project_path         $_git_root/projects/$_project_name
set _rundir               $_project_path/rundir

set _file_list            $_project_path/scripts/synth_file_list.lst
set _fpga_part            "xc7z020clg400-1"
set _board_part           "digilentinc.com:arty-z7-20:part0:1.0"
set _top_module_name      "project_top"

#set _xip_timing_constraints   "$_project_path/constraints/timing_constraints.tcl"
set _xip_timing_constraints   ""
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


# Block design
set _bd_design_name "bd_design_0"
set _fclk_freq_mhz  "125"

# Create the rundir
if [file isdirectory $_rundir] {
  file delete -force $_rundir
}
file mkdir             $_rundir
set _current_directory [pwd]
cd $_rundir

setup_project $_git_root $_project_name $_rundir $_fpga_part $_board_part $_file_list $_xip_properties $_ip_interfaces $_constraints $_fclk_freq_mhz $_bd_design_name

cd $_current_directory








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