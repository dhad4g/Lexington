# Target library
set libDir /opt/cadence_roy/library
set target_library "$libDir/fsd0a_90nm_generic_core/timing/fsd0a_a_generic_core_tt1v25c.db"
set link_library "* $target_library"

set scriptDir [file dirname [file normalize [info script]]]
set projDir [file normalize "${scriptDir}/../"]
set rtlDir "${projDir}/rtl"
set incDir "${projDir}/rtl"

lappend search_path $incDir


# Parse arguments
if { ![info exists top] } {
    puts "Error: top module must be set"
    exit 1
}
set top_src "${rtlDir}/${top}.sv"
# puts "Top Module: $top_src"

# Parse dependencies
set dependencies [exec grep -E "^//depend " $top_src | sed -e "s,^//depend ,${rtlDir}/,"]
set dependencies [split $dependencies "\n"]
# puts "Dependencies:"
# puts "$dependencies"

set_attr auto_ungroup false


# Compile
analyze -format sverilog $top_src
foreach depend $dependencies {
    analyze -format sverilog [ glob $depend ]
}

# Check
elaborate $top -architecture verilog -library WORK

# specify the wire load model to be used by the synthesis engine for
# timing optimizations
set_wire_load_model -name G50K

# specify the area constraint for the design (note that in default mode)
# the timing constraint will have priority over the area constraints
set_max_area 555000

# create the clock for the design with the period 0.6 ns
create_clock clk -period 1 -name clk
set_drive 0 clk
dont_touch_network clk

# set the delay at the input and output ports relative to the clock.
set_input_delay 0 -max -clock clk [all_inputs]
set_output_delay 0 -max -clock clk [all_outputs]


# Check design
check_design > check_design.txt
check_timing > check_timing.txt

#create the unique instances
uniquify

# do the mapping now
compile -map_effor medium
#compile -map_effort medium -ungroup_all
#compile_ultra

#Export netlist for post-synthesis simulation into synth_netlist.v
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output "${top}_netlist_synopsys.v"
write_sdc "${top}.sdc"

#Generate reports
report_area > area_report.txt
report_timing > timing_report.txt
report_power > power_report.txt
report_constraint -all_violators > violator_report.txt
report_register -level_sensitive > latch_report.txt


# Exit if not interractive
if { ![info exists interract] } {
    exit
}
