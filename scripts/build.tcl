proc usage {} {
    set SCRIPT_NAME $argv0
    puts ""
    puts "usage: $SCRIPT_NAME \[option\]... -target <target> <src file(s)>..."
    puts ""
    puts "    -target <target>      Target name (ex: Basys3)"
    puts "    <src file(s)>         One or more Verilog source files"
    puts ""
    puts "    -i, -include_dirs     Include directory"
    puts "    -v, -verbose          Disable message limits"
    puts "        -debug            Add debug core"
    puts "    -h, -help             Prints this usage message"
    puts ""
}

# Parse arguments
if { $argc < 1} {
    puts "ERROR: Build script requires at least 1 argument"
    usage
    exit 1
}
set ind_dir ""
set debug 0
lappend sv_files
for {set i 0} {$i < $argc} {incr i} {
    set option [string trim [lindex $argv $i]]
    switch -regexp -- $option {
        "^--?target"            { incr i; set target [lindex $argv $i] }
        "^(-i|--?include_dirs)" { incr i; set inc_dir [lindex $argv $i]}
        "^(-v|--?verbose)"      { set_param messaging.defaultLimit 1000 }
        "^--?debug"             { set debug 1}
        "^(-h|--?help)"         { usage; exit 0}
        default {
            lappend sv_files [lindex $argv $i]
        }
    }
}


# Set number of CPUs
proc numberOfCPUs {} {
    # Windows puts it in an environment variable
    global tcl_platform env
    if {$tcl_platform(platform) eq "windows"} {
        return $env(NUMBER_OF_PROCESSORS)
    }
    # Check for sysctl (OSX, BSD)
    set sysctl [auto_execok "sysctl"]
    if {[llength $sysctl]} {
        if {![catch {exec {*}$sysctl -n "hw.ncpu"} cores]} {
            return $cores
        }
    }
    # Assume Linux, which has /proc/cpuinfo, but be careful
    if {![catch {open "/proc/cpuinfo"} f]} {
        set cores [regexp -all -line {^processor\s} [read $f]]
        close $f
        if {$cores > 0} {
            return $cores
        }
    }
    # No idea what the actual number of cores is; exhausted all our options
    # Fall back to returning 4
    return 4
}
set_param general.maxThreads [numberOfCPUs]


# Load sources
read_verilog -sv $sv_files
read_xdc "${target}.xdc"

# Run Synthesis
synth_design -top $target -include_dirs $inc_dir -part xc7a35tcpg236-1 -flatten_hierarchy none
write_verilog -force post_synth.v

# Create debug core (Integrated Logic Analyzer)
if {$debug} {
    create_debug_core ila0 ila
    set dbg_core [get_debug_cores ila0]
    # ILA Properties
    set_property C_DATA_DEPTH 1024 $dbg_core
    set_property C_TRIGIN_EN false $dbg_core
    set_property C_TRIGOUT_EN false $dbg_core
    set_property C_ADV_TRIGGER false $dbg_core
    set_property C_INPUT_PIPE_STAGES 0 $dbg_core
    set_property C_EN_STRG_QUAL false $dbg_core
    set_property ALL_PROBE_SAME_MU true $dbg_core
    set_property ALL_PROBE_SAME_MU_CNT 1 $dbg_core
    # Connect clk port
    set_property port_width 1 [get_debug_ports ila0/clk]
        connect_debug_port ila0/clk [get_nets [list core_clk]]
    # Connect probes
    set_property port_width 32 [get_debug_ports ila0/probe0]
        connect_debug_port ila0/probe0 [get_nets -of [get_pins SOC/CORE0/PC/pc]]
    # create_debug_port ila0 probe
    #     set_property port_width 32 [get_debug_ports ila0/probe1]
    #     connect_debug_port ila0/probe1 [get_nets [list GPIOx_mode]]
}

# Implement (optimize, place, route)
opt_design
place_design
phys_opt_design
#write_checkpoint -force post_place
route_design


# Generate Reports
report_timing_summary -file post_route_timing.rpt
report_utilization -file post_route_utilization.rpt
report_power -file post_route_power.rpt
report_drc -file post_imp_drc.rpt

# Make bitstream
write_bitstream -force "${target}.bit"
