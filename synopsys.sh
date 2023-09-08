#!/bin/bash

PROJ_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"

DC_OPTS=""
PT_OPTS=""

source "${PROJ_DIR}/scripts/utils.sh"


function usage {
    cat <<USAGE_EOF

usage: $SCRIPT_NAME [option]... <top_module>

    <top_module>        Name of top module for synthesis

    -i                  enable interractive mode
    --sta               Performs static timing analysis after synthesis
    --sta-only          Skip synthesis and only run STA
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
interract=false
synth=true
sta=false
clean=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        -i)
            interract=true
            echo "Using interractive mode"
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
        --clean)
            clean=true
            echo "Cleaning build directory"
            shift
            ;;
        -* | --*)
            >&2 echo "Unkown argument $1"
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


BUILD_DIR="${PROJ_DIR}/build/synth/$top"
if $clean; then
    rm -rf $BUILD_DIR
fi
mkdir -p $BUILD_DIR
cd $BUILD_DIR

TCL_CMD="set top $top"
if $synth; then
    if $interract && (! $sta); then
        dc_shell $DC_OPTS -f "${PROJ_DIR}/scripts/dc.tcl" -x "$TCL_CMD; set interract 1"
    else
        dc_shell $DC_OPTS -f "${PROJ_DIR}/scripts/dc.tcl" -x "$TCL_CMD" | $OUT_FORMAT
    fi
fi

if $sta; then
    if $interract; then
        pt_shell $PT_OPTS -f "${PROJ_DIR}/scripts/pt.tcl" -x "$TCL_CMD; set interract 1"
    else
        pt_shell $PT_OPTS -f "${PROJ_DIR}/scripts/pt.tcl" -x "$TCL_CMD" | $OUT_FORMAT
    fi
fi
