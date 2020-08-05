# Created clock
create_clock -add -name clk -period 8.00 -waveform {0.0 4.0} [get_ports { clk }]