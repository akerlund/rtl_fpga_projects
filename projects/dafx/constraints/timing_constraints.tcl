#create_clock -name sys_clk -period 8.00 -waveform {0.0 4.0} [get_ports { clk }]
#create_generated_clock -name clk_mclk_int -source [get_pins -hier -regexp .*car_cs5343_i0/plle2_base_i0/CLKIN1] -multiply_by 56 -divide_by 310 [get_pins -hier -regexp .*car_cs5343_i0/plle2_base_i0/CLKOUT0]
set_clock_groups -asynchronous -group [get_clocks clk_fpga_0] -group [get_clocks clk_mclk_int]
set_property -quiet ASYNC_REG TRUE [get_cells -hier -regexp .*reset_synchronizer_core_i0/reset_origin_n.*]
set_property -quiet ASYNC_REG TRUE [get_cells -hier -regexp .*io_synchronizer_core_i0/bit_egress.*]
set_property -quiet ASYNC_REG TRUE [get_cells -hier -regexp .*cdc_bit_sync_core_i0/dst_bit.*]
