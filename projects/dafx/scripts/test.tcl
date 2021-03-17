#!/usr/bin/env tclsh

# Send a list to a proc and print it
proc print_a_list {some_list} {

  foreach var $some_list {
    puts $var
  }
}

set test_list [list\
  DESCRIPTION  \
  VENDOR       \
  LIBRARY      \
  NAME         \
  VERSION      \
  DISPLAY_NAME \
  DESCRIPTION ]


print_a_list $test_list

# Send a dict to a proc and print it
proc print_a_dict {some_dict} {

  # Vendor
  if {[dict exists $some_dict ip_vendor]} {
    puts [dict get $some_dict ip_vendor]
  }

  # Library
  if {[dict exists $some_dict ip_library]} {
    puts [dict get $some_dict ip_library]
  }

  # Name
  if {[dict exists $some_dict ip_name]} {
    puts [dict get $some_dict ip_name]
  }

  # Version
  if {[dict exists $some_dict ip_version]} {
    puts [dict get $some_dict ip_version]
  }

  # Display name
  if {[dict exists $some_dict ip_display_name]} {
    puts [dict get $some_dict ip_display_name]
  }

  # Description
  if {[dict exists $some_dict ip_description]} {
    puts [dict get $some_dict ip_description]
  }
}



set test_dict [dict create \
  ip_vendor       aerland \
  ip_library      aerland_ip_lib \
  ip_name         project_top \
  ip_version      1.0 \
  ip_display_name project_top \
  ip_description  ip_testing \
]

print_a_dict $test_dict


# Send a dict to a proc and print it
proc print_a_dict_of_lists {some_dict_list} {

  puts "Clocks"
  foreach var [dict get $some_dict_list clocks] {
    puts "clock_name = [dict get $var name]"
    puts "clock_hz   = [dict get $var freq_hz]"
  }

  puts "Resets"
  foreach var [dict get $some_dict_list resets] {
    puts $var
  }

  puts "IO"
  foreach var [dict get $some_dict_list data_io] {
    puts "[dict get $var name] [dict get $var dir]"
  }

}


set test_dict_lists [dict create                         \
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

print_a_dict_of_lists $test_dict_lists



set list_0 [list "a " "b " "c "]
puts [join $list_0]


#set _xip_timing_constraints   "/constraints/timing_constraints.tcl"
set _xip_timing_constraints   ""
set _xip_physical_constraints ""
set _top_timing_constraints   ""
set _top_physical_constraints "/constraints/physical_constraints.tcl"

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

puts [join [dict get $_constraints xip_timing]]
puts [join [dict get $_constraints xip_physical]]



puts "test is:  [file isdirectory test]"
puts "test2 is:  [file isdirectory test2]"