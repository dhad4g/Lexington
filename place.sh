#!/bin/bash

PROJ_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"
BASENAME="core"
BUILD_DIR="${PROJ_DIR}/build/synth/${BASENAME}"

source "${PROJ_DIR}/scripts/utils.sh"


mkdir -p $BUILD_DIR
cd $BUILD_DIR

innovus -files "${PROJ_DIR}/scripts/vlsi/place.tcl" 2>&1 | $OUT_FORMAT
