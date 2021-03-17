# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
set _git_root             [exec git rev-parse --show-toplevel]
puts "Git root = ($_git_root)"

set _project_name         "dafx"
set _project_path         $_git_root/projects/$_project_name
set _rundir [pwd]
puts "_project_path = ($_project_path)"
puts "pwd = ([pwd])"

set _file_list            $_rundir/rtl_files.lst
set _fpga_part            "xc7z020clg400-1"
set _board_part           "digilentinc.com:arty-z7-20:part0:1.0"
set _top_module_name      "project_top"

#set _xip_timing_constraints   "$_project_path/constraints/timing_constraints.tcl"
set _xip_timing_constraints   ""
set _xip_physical_constraints ""
set _top_timing_constraints   "$_project_path/constraints/timing_constraints.tcl"
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


set _xip_properties [dict create   \
  ip_vendor       "aerland.se"     \
  ip_library      "aerland_ip_lib" \
  ip_name         "project_top"    \
  ip_version      "1.0"            \
  ip_display_name "project_top"    \
  ip_description  "project_top"    \
]

set _ip_interfaces [dict create                          \
  clocks  [list [dict create name clk freq_hz 125000000] \
          ]                                              \
  resets  [list rst_n                                    \
          ]                                              \
  irq     [list irq_0                                    \
                irq_1                                    \
          ]                                              \
  data_io [list [dict create name "led_0"       dir "O"] \
                [dict create name "led_1"       dir "O"] \
                [dict create name "led_2"       dir "O"] \
                [dict create name "led_3"       dir "O"] \
                [dict create name "btn_0"       dir "I"] \
                [dict create name "btn_1"       dir "I"] \
                [dict create name "btn_2"       dir "I"] \
                [dict create name "btn_3"       dir "I"] \
                [dict create name "sw_0"        dir "I"] \
                [dict create name "sw_1"        dir "I"] \
                [dict create name "cs_tx_mclk"  dir "O"] \
                [dict create name "cs_tx_lrck"  dir "O"] \
                [dict create name "cs_tx_sclk"  dir "O"] \
                [dict create name "cs_tx_sdout" dir "O"] \
                [dict create name "cs_rx_mclk"  dir "O"] \
                [dict create name "cs_rx_lrck"  dir "O"] \
                [dict create name "cs_rx_sclk"  dir "O"] \
                [dict create name "cs_rx_sdin"  dir "I"] \
          ]                                              \
]


# Block design
set _bd_design_name "bd_design_0"
set _fclk_freq_mhz  "125"

build_zynq $_project_name $_rundir $_fpga_part $_board_part $_file_list $_xip_properties $_ip_interfaces $_constraints $_fclk_freq_mhz $_bd_design_name
