#!/usr/bin/env bash

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR


cd $SRC_DIR

build_install() {
    for dir_name in $@; do
        cd "$dir_name/build"
	echo -n "building $dir_name ... "
        $SUDO make -j$MAKE_THREADS_NUMBER install
        cd ../../
    done
}

build_install "openhrp3" "hrpsys-base" "HRP2" "HRP2KAI" "hmc2" "hrpsys-private" "hrpsys-humanoid"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
build_install "choreonoid"
fi

