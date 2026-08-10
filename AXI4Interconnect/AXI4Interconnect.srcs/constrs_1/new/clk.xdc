
create_clock -period 10.000 -name ACLK_i -waveform {0.000 5.000} [get_ports ACLK_i]
config_timing_analysis -ignore_io_paths yes
