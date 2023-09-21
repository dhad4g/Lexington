#!/bin/bash

PROJ_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"
RTL_SRC_DIR="${PROJ_DIR}/rtl"

DC_OPTS=""
PT_OPTS=""

source "${PROJ_DIR}/scripts/utils.sh"


function usage {
    cat <<USAGE_EOF

usage: $SCRIPT_NAME [option]... <top_module>

    <top_module>        Name of top module for synthesis

    -i                  enable interactive mode
    --sta               Performs static timing analysis after synthesis
    --sta-only          Skip synthesis and only run STA
    --wrap              Wrap combinatorial module for static timing analysis
    --clk               If wrapping, name of clock input port (default: clk)
    --clean             Clean the build directory before starting
    -h, --help          Prints this usage message
USAGE_EOF
}

# Check args
if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided"
    exit 1
fi

# Parse args
top=""
interact=false
synth=true
sta=false
wrap=false
clk="clk"
clean=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        -i)
            interact=true
            echo "Using interactive mode"
            shift
            ;;
        --sta)
            sta=true
            echo "Static Timing Analysis enabled"
            shift
            ;;
        --sta-only)
            synth=false
            sta=true
            echo "Skipping Synthesis"
            echo "Running Static Timing Analysis"
            shift
            ;;
        --wrap)
            wrap=true
            echo "Wrapping combinatorial module for Static Timing Analysis"
            shift
            ;;
        --clk)
            shift
            clk=("$1")
            shift
            ;;
        --clean)
            clean=true
            echo "Cleaning build directory"
            shift
            ;;
        -* | --*)
            >&2 echo "Unknown argument $1"
            exit 1
            ;;
        *)
            if [ "$top" != "" ]; then
                >&2 echo "Only one module can be selected"
                usage
                exit 1
            fi
            top=("$1")
            shift
    esac
done


top_path="$top"
top_src="${RTL_SRC_DIR}/${top}.sv"
top=$(echo "$top_path" | sed -E 's,.*/,,')
BUILD_DIR="${PROJ_DIR}/build/synth/${top_path}"

if $clean; then
    rm -rf $BUILD_DIR
fi
mkdir -p $BUILD_DIR
cd $BUILD_DIR

if $wrap; then
    top_dest="${BUILD_DIR}/${top}_wrapper.sv"
    "${PROJ_DIR}/scripts/make-comb-wrapper.py" "$top_src" --clk "$clk" > "${top_dest}"
    rval=$?
    if [ "$rval" != "0" ]; then
        echo "Wrapper script failed"
        exit $rval
    fi
    top="${top}_wrapper"
    top_src="$top_dest"
fi

TCL_CMD="set top $top; set top_src $top_src"
if $synth; then
    if $interact && (! $sta); then
        dc_shell $DC_OPTS -f "${PROJ_DIR}/scripts/dc.tcl" -x "$TCL_CMD; set interact 1"
        rval=$?
    else
        dc_shell $DC_OPTS -f "${PROJ_DIR}/scripts/dc.tcl" -x "$TCL_CMD" | $OUT_FORMAT
        rval=$?
    fi
    if [ "$rval" != "0" ]; then
        echo
        echo "Synthesis failed"
        exit $rval
    fi
fi

if $sta; then
    if $interact; then
        pt_shell $PT_OPTS -f "${PROJ_DIR}/scripts/pt.tcl" -x "$TCL_CMD; set interact 1"
        rval=$?
    else
        pt_shell $PT_OPTS -f "${PROJ_DIR}/scripts/pt.tcl" -x "$TCL_CMD" | $OUT_FORMAT
        rval=$?
    fi
    if [ "$rval" != "0" ]; then
        echo
        echo "Static Timing Analysis failed"
        exit $rval
    fi
fi
