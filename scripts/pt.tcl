# Set target library
set libDir /opt/cadence_roy/library
set target_library "$libDir/fsd0a_90nm_generic_core/timing/fsd0a_a_generic_core_tt1v25c.db"
set link_path "* $target_library"


# Parse arguments
if { ![info exists top]} {
    puts "Error: top module must be set"
    exit 1
}
set netlist "${top}_netlist_synopsys.v"

# Read source
read_verilog $netlist
link_design $top


# Create clock and set delay
create_clock clk -period 1 -n clk
set_input_delay 0 -max -clock clk [all_inputs]
set_output_delay 0 -max -clock clk [all_outputs]


set timing_save_pin_arrival_and_slack true
set timing_report_use_worst_parallel_cel_arc true

# Check timing
check_timing -include loops > pt_check_timing.txt

report_analysis_coverage > pt_coverage_report.txt

# Reports
report_design > pt_design_report.txt
report_hierarchy > pt_hierarchy_report.txt
report_net > pt_net_report.txt
report_port > pt_port_report.txt
report_reference > pt_reference_report.txt
report_global_timing > pt_global_timing_report.txt
report_timing -max_paths 1000 > pt_timing_report.txt
#report_timing -max_paths 1000 -through {pc ibus fetch decoder alu lsu dbus regfile csr trap mtime} > pt_timing_report.txt
report_bottleneck -max_cells 100 > pt_bottleneck_report.txt


# Exit if not interractive
if { ![info exists interract] } {
    exit
}
