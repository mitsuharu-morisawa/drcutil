#!/usr/bin/env bash

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR


cd $SRC_DIR

build_install() {
    for dir_name in $@; do
	if [ -e $dir_name ]; then
            cd "$dir_name/build"
	    echo -n "building $dir_name ... "
	    if [ "${VERBOSE-0}" -eq 0 ]; then
		$SUDO make -j$MAKE_THREADS_NUMBER install > $SRC_DIR/${dir_name}.log 2>&1
	    else
		$SUDO make -j$MAKE_THREADS_NUMBER install
	    fi
	    if [ "$?" -eq 0 ]
	    then
		echo "success"
	    else
		echo -e "\e[31mfail\e[m"
	    fi
            cd ../../
	fi
    done
}

build_install "openhrp3" "hrpsys-base" "HRP2" "HRP2KAI" "HRP5P" "hmc2" "hrpsys-private" "hrpsys-humanoid"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
build_install "choreonoid"
else
build_install "flexiport" "hokuyoaist" "rtchokuyoaist"
fi

