#!/bin/bash

RED="\x1b[31m"
GREEN="\x1b[32m"
YELLOW="\x1b[33m"
BLUE="\x1b[34m"
NORMAL="\x1b[0m"

SUCCESS_FORMAT="s,(PASS(ED)?|SUCCESS(FULLY?)?),$GREEN\1$NORMAL,I" # highlight green
WARN_FORMAT="s,(.*WARN.*),$YELLOW\1$NORMAL,I" # highlight yellow
ERROR_FORMAT="s,(.*(FAIL|ERROR).*),$RED\1$NORMAL,I" # highlight red
# ERROR2_FORMAT="s,((FAIL|ERROR):?)(\s)(.*/)([^/]+\.s?v((.?\sLine)?:?\s?[0-9]+)?)(.*),$RED\1\3$BLUE\5$RED\3\4\5\8$NORMAL,I" # display filename and line at beginning
 ERROR2_FORMAT="s,((FAIL|ERROR):?)(\s)(.*/)([^/]+\.s?v((.?\sLine)?:?\s?[0-9]+)?)(.*),$RED\1\3$RED\3\4$YELLOW\5$RED\8$NORMAL,I" # highlight filename and line
_FORMATS="$SUCCESS_FORMAT;$WARN_FORMAT;$ERROR_FORMAT;$ERROR2_FORMAT;"
OUT_FORMAT="sed -E $_FORMATS"
function out_format () {
    $OUT_FORMAT
}


# File path conversions
function win_to_wsl_path() {
    # non-windows paths will not be modified
    echo "$@" | sed -E 's,\\,/,g;s,C\://?,/mnt/c/,g'
}
function wsl_to_win_path() {
    # replaces '/mnt/c' with 'C:/'
    echo "$@" | sed -E 's,/mnt/c/,C\:/,g'
}


# Function for WSL support
function special_exec () {
    echo "$@"
    which powershell.exe > /dev/null
    if [ "$?" == "0" ]; then
        args=$(wsl_to_win_path "$@")
        "/mnt/c/Program Files/Git/bin/bash.exe" -c "$args"
        rval=$?
        if [ "$rval" != "0" ]; then
            exit $rval
        fi
    else
        $@
    fi
}


# Parse dependencies
#   args: <src file> [DIR_PREFIX]
#   returns: rval variable set to space separated list of dependencies
function parse_depends () {
    if [ $# -lt 1 ]; then
        >$2 echo "Dependency parser function requires source file as argument"
        exit 1
    fi
    if [ $# -ge 2 ]; then
        prefix="$2/"
    else
        prefix=""
    fi
    SRC_FILE=$1
    readarray -t dependencies < <(grep --no-filename -E '^//depend ' $SRC_FILE | sed -e 's,^\/\/depend ,,' )
    rval=""
    for i in "${!dependencies[@]}"; do
        dependencies[i]=$(sed -e 's,\r,,' <<<${dependencies[$i]})
        if [ $# -ge 2 ]; then
            dependencies[i]="${prefix}${dependencies[$i]}"
        fi
        rval="$rval ${dependencies[$i]}"
        echo "    ${dependencies[$i]}"
    done
}


# Execute macro commands
#   args: <src file(s)> [ENV_VARS]
#   returns: nothing
function exec_macro_cmds () {
    if [ $# -lt 1 ]; then
        >&2 echo "Execute macro commands function requires source file as argument"
        exit 1
    fi
    SRC_FILE=$1
    readarray -t cmds < <(grep --no-filename -E '^//cmd ' "$SRC_FILE" | sed -e 's/^\/\/cmd //' | sed -e "s,\\\${PROJ_DIR},$PROJ_DIR,g")
    for i in "${!cmds[@]}"; do
        cmd="${cmds[$i]}"
        if [ $# -ge 2 ]; then
            cmd="export $2; $cmd"
        fi
        echo "$cmd"
        bash -c "$cmd" | $OUT_FORMAT # run each cmd in it's own subshell
        rval=$PIPESTATUS
        echo
        if [ "$rval" != "0" ]; then
            >&2 echo -e "${RED}FAIL: User command failed with exit code $rval"
            >&2 echo
            exit $rval
        fi
    done
    echo
}
