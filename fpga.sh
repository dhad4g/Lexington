#!/bin/bash

PROJ_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"

RTL_SRC_DIR="${PROJ_DIR}/rtl"
INC_DIR="${PROJ_DIR}/rtl"
SW_PROJ_DIR="${PROJ_DIR}/sw/projects"

VIVADO_OPTS="-mode tcl"

# Include common functions and definitions such as OUT_FILTER and special_exec()
source "${PROJ_DIR}/scripts/utils.sh"


function usage {
    cat <<USAGE_EOF

usage: $SCRIPT_NAME [option]... <target> <sw project>

    <target>            Name of the target board (ex: Basys3)
    <sw project>        Name of software project (ex: blink)

    -v, --verbose       Disable message limits
        --debug         Add debug core
    -h, --help          Prints this usage message

USAGE_EOF
}


# Check for empty arguments
if  [ $# -eq 0 ]; then
    >&2 echo "No arguments provided"
    usage
    exit 1
fi

# Parse args
target=""
proj=""
verbose=""
debug=""
while [[ $# -gt 0 ]]; do
   case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        -v | --verbose)
            verbose="-v"
            echo "Verbose output enabled. Message limit increased to 1000."
            shift
            ;;
        --debug)
            debug="-debug"
            echo "Debug core enable"
            shift
            ;;
        -* | --*)
            >&2 echo "Unknown argument $1"
            exit 1
            ;;
        *)
            if [ "$target" == "" ]; then
                target=("$1")
            elif [ "$proj" == "" ]; then
                proj=("$1")
            else
                >&2 echo "Only one software project can be provided"
                usage
                exit 1
            fi
            shift
    esac
done

top="${RTL_SRC_DIR}/${target}.sv"
xdc="${PROJ_DIR}/scripts/${target}.xdc"

# Check target files exist
if [ ! -f "$top"]; then
    >&2 echo "Target top file '$top' does not exist"
    exit 1
fi
if [ ! -f "$xdc"]; then
    >&2 echo "Target XDC file '$xdc' does not exist"
    exit 1
fi

# Check project exists
if [ ! -f "${SW_PROJ_DIR}/$proj/Makefile" ]; then
    >&2 echo "Software project '$proj' Makefile does not exist"
    echo "A software project Makefile should be located at ${SW_PROJ_DIR}/Makefile"
    exit 1
fi

echo "Beginning compile and implementation for project $proj:"
mkdir -p "${PROJ_DIR}/build/implement"
cd "${PROJ_DIR}/build/implement"

# Compile software
bash -c "cd ${SW_PROJ_DIR}/$proj && make build dump" | $OUT_FORMAT
rval=$PIPESTATUS
if [ "$rval" != "0" ];then
    >&2 echo -e "${RED}FAIL: Software project compilation failed with exit code $rval"
    >&2 echo
    exit $rval
fi
cp "${SW_PROJ_DIR}/$proj/rom.hex" .

# Execute macro commands
exec_macro_cmds "$top"
echo

# Find dependencies
echo "    $top"
parse_depends $top "$RTL_SRC_DIR"
sv_files="$top $rval"
echo

# Copy XDC
cp "${PROJ_DIR}/scripts/${target}.xdc" .

# Implement
TCL_ARGS="$verbose $debug -i $INC_DIR -target $target $sv_files"
special_exec vivado $VIVADO_OPTS -source "${PROJ_DIR}/scripts/build.tcl" -tclargs "$TCL_ARGS" 2>&1 | $OUT_FORMAT
