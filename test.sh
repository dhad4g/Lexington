#!/bin/bash

PROJ_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"

RTL_SRC_DIR="${PROJ_DIR}/rtl"
INC_DIR="${PROJ_DIR}/rtl"
TB_DIR="${PROJ_DIR}/testbench"

XVLOG_OPTIONS="-sv -i ${INC_DIR}"


RED="\x1b[31m"
GREEN="\x1b[32m"
YELLOW="\x1b[33m"
BLUE="\x1b[34m"
NORMAL="\x1b[0m"

SUCCESS_FORMAT="s,(PASS(ED)?|SUCCESS),$GREEN\1$NORMAL,I" # highlight green
WARN_FORMAT="s,(.*WARN.*),$YELLOW\1$NORMAL,I" # highlight yellow
ERROR_FORMAT="s,(.*(FAIL|ERROR).*),$RED\1$NORMAL,I" # highlight red
ERROR2_FORMAT="s,((FAIL|ERROR):?)(\s)(.*/)([^/]+\.s?v((.?\sLine)?:?\s?[0-9]+)?)(.*),$RED\1\3$BLUE\5$RED\3\4\5\8$NORMAL,I" # display filename and line at beginning
OUT_FORMAT="sed -E $SUCCESS_FORMAT;$WARN_FORMAT;$ERROR_FORMAT;$ERROR2_FORMAT"


function usage {
    cat <<USAGE_EOF

usage: $SCRIPT_NAME [OPTION]... [MODULE]...

    <module>    Name of module test

    -a, --all       Run tests for all modules
        --check     Compile and elaborate only (no sim)
    -h, --help      Prints this usage message

USAGE_EOF
}


# Check for empty arguments
if  [ $# -eq 0 ]; then
    >&2 echo "No arguments provided"
    usage
    exit 1
fi


function sim() {
    if [ $# -eq 0 ]; then
        >&2 echo "Function sim called with no module argument"
        exit 2
    fi
    module=$(echo "$1" | sed -E 's/.*\///')
    module_path="$1"
    module_prefix=$(echo "$1" | sed -E 's/\/?[^\/]*$//')
    source="${RTL_SRC_DIR}/${module_path}.sv"
    testbench="${TB_DIR}/${module_path}_TB.sv"
    echo "$module_path"
    echo "    $source"
    echo "    $testbench"
    if [ $# -eq 1 ]; then
        check_only=false
    else
        check_only=$2
    fi
    mkdir -p "build/sim/$module_path"
    cd "build/sim/$module_path"
    # find dependencies
    dependencies=($(grep --no-filename -E '^//depend ' "$source" "$testbench" | sed -e 's/^\/\/depend //' ))
    sv_files="$source:$testbench"
    for i in "${!dependencies[@]}"; do
        dependencies[i]="${RTL_SRC_DIR}/${dependencies[$i]}"
        sv_files="$sv_files:${dependencies[$i]}"
        echo "    ${dependencies[$i]}"
    done
    echo
    # execute special commands
    readarray -t cmds < <(grep --no-filename -E '^//cmd ' "$source" "$testbench" | sed -e 's/^\/\/cmd //' | sed -e "s,\\\${PROJ_DIR},$PROJ_DIR,")
    for i in "${!cmds[@]}"; do
        echo "${cmds[$i]}"
        $SHELL -c "${cmds[$i]}" # run each cmd in it's own subshell
        rval=$PIPESTATUS
        echo
        if [ "$rval" != "0" ]; then
            >&2 echo -e "${RED}FAIL: User command failed with exit code $rval"
            >&2 echo
            return $rval
        fi
    done
    echo
    # compile
    #xvlog $XVLOG_OPTIONS $dependencies $source $testbench | $OUT_FORMAT
    xvlog $XVLOG_OPTIONS $sv_files | $OUT_FORMAT
    rval=$PIPESTATUS
    #rval=$?
    if [ "$rval" == "0" ]; then
        echo
        echo -e "${BLUE}Compile for $module_path complete${NORMAL}"
        echo
    else
        >&2 echo
        >&2 echo -e "${RED}FAIL: Compile failed for $module_path${NORMAL}"
        >&2 echo "Check build/sim/$module_path/xvlog.log"
        >&2 echo
        return $rval
    fi
    # elaborate
    xelab -debug typical -s sim ${module}_TB | $OUT_FORMAT
    rval=$PIPESTATUS
    if [ "$rval" = "0" ]; then
        echo
        echo -e "${BLUE}Elaborate for $module_path complete${NORMAL}"
        echo
    else
        >&2 echo
        >&2 echo -e "${RED}FAIL: Elaborate failed for $module_path${NORMAL}"
        >&2 echo "Check build/sim/$module_path/xelab.log"
        >&2 echo
        return $rval
    fi
    # simulate
    if $check_only; then
        return $rval
    else
        xsim --runall sim | $OUT_FORMAT
        rval=$PIPESTATUS
        if [ "$rval" = "0" ]; then
            #echo -e "${BLUE}Simulate for $module complete${NORMAL}"
            echo
        else
            >&2 echo
            >&2 echo -e "${RED}FAIL: Simulate failed for $module_path${NORMAL}"
            >&2 echo
            return $rval
        fi
        tail -n 2 ${module}.log | grep PASS > /dev/null
        return $?
    fi
}




all=false
check_only=false
modules=()
while [[ $# -gt 0 ]]; do
   case "$1" in
        -a | --all)
            all=true
            shift
            ;;
        --check)
            check_only=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        -* | --*)
            >&2 echo "Unknown argument $1"
            exit 1
            ;;
        *)
            modules+=("$1")
            shift
    esac
done

if $all; then
    if [ "${#modules[@]}" -gt 0 ]; then
        >&2 echo "Module names must not be provided when using the --all option"
        exit 1
    fi
    modules=$(find $TB_DIR | grep -E '_TB\.sv$' | sed -e 's/_TB\.sv$//' | sed -e "s/${TB_DIR}\///")
fi

fail=0
summary="Simulation testing complete"
for module in $modules; do
    sim $module $check_only
    rval=$?
    if [ "$rval" != "0" ]; then
        fail=1
        echo
        >&2 echo -e "Test for module $module ${RED}FAILED${NORMAL}. Exit value $rval"
        summary="${summary}\n${module} ${RED}FAILED${NORMAL}"
    else
        summary="${summary}\n${module} ${GREEN}PASSED${NORMAL}"
    fi
    echo ""
done

if [[ $fail -gt 0 ]]; then
    echo ""
    echo -e "All modules ${GREEN}PASSED${NORMAL}"
fi

exit $fail
