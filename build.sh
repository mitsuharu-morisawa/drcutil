#!/usr/bin/env bash

source config.sh
source packsrc.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR
set -E -o pipefail

export LSAN_OPTIONS="exitcode=0"

cd $SRC_DIR

build_install_OpenRTM-aist() {
    cd OpenRTM-aist
    if [ `cat svn.log | wc -l` != 2 ]; then
        echo -n "building OpenRTM-aist ... "
        $SUDO make -j$MAKE_THREADS_NUMBER install > $SRC_DIR/OpenRTM-aist.log 2>&1
        if [ "$?" -eq 0 ]
        then
	    echo "success"
        else
	    echo -e "\e[31mfail\e[m"
        fi
    fi
    cd ../
}

build_install() {
    dir_name=$1
    if [ -e $dir_name ]; then
        cd "$dir_name/$BUILD_SUBDIR"
	echo -n "building $dir_name ... "
	if [ "${VERBOSE-0}" -eq 0 ]; then
	    $SUDO make -j$MAKE_THREADS_NUMBER install > $SRC_DIR/${dir_name}.log 2>&1
	else
	    $SUDO make -j$MAKE_THREADS_NUMBER install 2>&1 | tee $SRC_DIR/${dir_name}.log
	fi
	if [ "$?" -eq 0 ]
	then
	    echo "success"
            built_dirs="$built_dirs $dir_name"
	else
	    echo -e "\e[31mfail\e[m"
	fi
        cd ../../
    fi
}

built_dirs=
if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    if [ $package = "OpenRTM-aist" ]; then
        build_install_OpenRTM-aist
    else
        build_install $package
    fi
done

if [ $# = 0 ]; then
    packsrc $built_dirs
    $SUDO mv robot-sources.tar.bz2 $PREFIX/share/
fi
