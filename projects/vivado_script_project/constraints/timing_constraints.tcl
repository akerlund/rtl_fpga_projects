# Created clock
create_clock -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }]