#!/usr/bin/env bash

DRCUTIL=$PWD

source config.sh
source packsrc.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR
built_dirs=

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH

if [ "$ENABLE_ASAN" -eq 1 ]; then
    BUILD_TYPE=RelWithDebInfo
    ASAN_OPTIONS=(-DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O2 -g -DNDEBUG -fsanitize=address" -DCMAKE_C_FLAGS_RELWITHDEBINFO="-O2 -g -DNDEBUG -fsanitize=address")
    # Report, but don't fail on, leaks in program samples during build.
    export LSAN_OPTIONS="exitcode=0"
else
    ASAN_OPTIONS=()
fi

cmake_install_with_option() {
    SUBDIR="$1"
    shift

    if [ ! -d "$SRC_DIR/$SUBDIR" ]; then
	return
    fi

    # check existence of the build directory
    if [ ! -d "$SRC_DIR/$SUBDIR/build" ]; then
        mkdir "$SRC_DIR/$SUBDIR/build"
    fi
    cd "$SRC_DIR/$SUBDIR/build"

    COMMON_OPTIONS=(-DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${ASAN_OPTIONS[@]}")
    echo cmake $(printf "'%s' " "${COMMON_OPTIONS[@]}" "$@") .. | tee config.log

    cmake "${COMMON_OPTIONS[@]}" "$@" .. 2>&1 | tee -a config.log

    $SUDO make -j$MAKE_THREADS_NUMBER install 2>&1 | tee $SRC_DIR/$SUBDIR.log

    built_dirs="$built_dirs $SUBDIR"
}

install_OpenRTM-aist() {
    cd $SRC_DIR/OpenRTM-aist
    if [ ! -e configure ]; then
	./build/autogen
    fi
    if [ $BUILD_TYPE != "Release" ]; then
	EXTRA_OPTION=(--enable-debug)
    else
	EXTRA_OPTION=()
    fi
    ./configure --prefix="$PREFIX" --without-doxygen "${EXTRA_OPTION[@]}"

    built_dirs="$built_dirs OpenRTM-aist"

    if [ "$ENABLE_ASAN" -eq 1 ]; then
	# We set -fsanitize=address here, after configure, because this
	# flag interferes with detecting the flags needed for pthreads,
	# causing problems later on.
	EXTRA_OPTION=(CXXFLAGS="-O2 -g3 -fsanitize=address" CFLAGS="-O2 -g3 -fsanitize=address")
    else
	EXTRA_OPTION=()
    fi

    $SUDO make -j$MAKE_THREADS_NUMBER install "${EXTRA_OPTION[@]}" \
	| tee $SRC_DIR/OpenRTM-aist.log
}

install_openhrp3() {
    cmake_install_with_option "openhrp3" -DCOMPILE_JAVA_STUFF=OFF -DBUILD_GOOGLE_TEST="$BUILD_GOOGLE_TEST" -DOPENRTM_DIR="$PREFIX"
}

install_octomap() { 
    cmake_install_with_option "octomap-$OCTOMAP_VERSION"
}

install_hrpsys-base() {
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
	EXTRA_OPTION=()
    else
	EXTRA_OPTION=(-DINSTALL_HRPIO=OFF)
    fi
    cmake_install_with_option hrpsys-base -DCOMPILE_JAVA_STUFF=OFF -DBUILD_KALMAN_FILTER=OFF -DBUILD_STABILIZER=OFF -DENABLE_DOXYGEN=OFF "${EXTRA_OPTION[@]}"
}

install_HRP2() {
    cmake_install_with_option HRP2 -DROBOT_NAME=HRP2KAI
}

install_HRP2KAI() {
    cmake_install_with_option HRP2KAI
}

install_HRP5P() {
    cmake_install_with_option HRP5P
}

install_sch-core() {
    cmake_install_with_option sch-core
}

install_hmc2() { 
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
	EXTRA_OPTION=()
    else
	EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=OFF)
    fi
    cmake_install_with_option hmc2 -DCOMPILE_JAVA_STUFF=OFF "${EXTRA_OPTION[@]}"
}

install_hrpsys-humanoid() { 
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
	EXTRA_OPTION=()
    else
	EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=OFF)
    fi
    cmake_install_with_option hrpsys-humanoid -DCOMPILE_JAVA_STUFF=OFF -DENABLE_SAVEDBG=$ENABLE_SAVEDBG "${EXTRA_OPTION[@]}"
}

install_hrpsys-private() {
    cmake_install_with_option hrpsys-private
}

install_state-observation() {
    cmake_install_with_option state-observation -DCMAKE_INSTALL_LIBDIR=lib
}

install_hrpsys-state-observation() {
    cmake_install_with_option hrpsys-state-observation
}

install_savedbg() {
    cmake_install_with_option savedbg -DSAVEDBG_FRONTEND_NAME=savedbg-hrp -DSAVEDBG_FRONTEND_ARGS="-P 'dpkg -l > dpkg' -f '$PREFIX/share/robot-sources.tar.bz2'"
}

install_trap-fpe() {
    if [ "$ENABLE_ASAN" -eq 1 ]; then
	TRAP_FPE_EXTRA_OPTION=(-DTRAP_FPE_SANITIZER_WORKAROUND=ON)
    else
	TRAP_FPE_EXTRA_OPTION=()
    fi
    # DynamoRIO doesn't seem to have an official install step.
    # We just unpack the distribution directly into $PREFIX.
    $SUDO tar -zxf $SRC_DIR/DynamoRIO-$DYNAMORIO_VERSION.tar.gz -C $PREFIX/share
    cmake_install_with_option trap-fpe "-DTRAP_FPE_BLACKLIST=$DRCUTIL/trap-fpe.blacklist.$DIST_KIND$DIST_VER" "-DDynamoRIO_DIR=$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/cmake" "${TRAP_FPE_EXTRA_OPTION[@]}"
}

install_choreonoid() {
    if [ "$IS_VIRTUAL_BOX" -eq 1 ]; then
      CHOREONOID_CMAKE_CXX_FLAGS="-DJOYSTICK_DEVICE_PATH=\"/dev/input/js1\" $CHOREONOID_CMAKE_CXX_FLAGS" #mouse integration uses /dev/input/js1 in virtualbox
    fi
    # FIXME?: This doesn't look right.  CMAKE_CXX_FLAGS is ignored
    # unless CMAKE_BUILD_TYPE is empty, which it is not by default.
    cmake_install_with_option "choreonoid" -DENABLE_CORBA=ON -DBUILD_CORBA_PLUGIN=ON -DBUILD_OPENRTM_PLUGIN=ON -DBUILD_PCL_PLUGIN=ON -DBUILD_OPENHRP_PLUGIN=ON -DBUILD_GRXUI_PLUGIN=ON -DBODY_CUSTOMIZERS="$SRC_DIR/HRP2/customizer/HRP2Customizer;$SRC_DIR/HRP5P/customizer/HRP5PCustomizer" -DBUILD_DRC_USER_INTERFACE_PLUGIN=ON -DCMAKE_CXX_FLAGS="$CHOREONOID_CMAKE_CXX_FLAGS" -DROBOT_HOSTNAME="$ROBOT_HOSTNAME"

    mkdir -p $HOME/.config/Choreonoid
    cp $DRCUTIL/.config/Choreonoid.conf $DRCUTIL
    sed -i -e "s#/home/vagrant/src#$SRC_DIR#g" $DRCUTIL/Choreonoid.conf
    sed -i -e "s#/home/vagrant/openrtp#$PREFIX#g" $DRCUTIL/Choreonoid.conf
    if [ ! -e $HOME/.config/Choreonoid/Choreonoid.conf ];then
	cp $DRCUTIL/Choreonoid.conf $HOME/.config/Choreonoid
    fi
}

install_flexiport() {
    cmake_install_with_option flexiport -DBUILD_DOCUMENTATION=OFF
}

install_hokuyoaist() {
    cmake_install_with_option hokuyoaist -DBUILD_DOCUMENTATION=OFF -DBUILD_PYTHON_BINDINGS=OFF
}

install_rtchokuyoaist() {
    cmake_install_with_option rtchokuyoaist -DBUILD_DOCUMENTATION=OFF
}

if [ $# = 0 ]; then # full install
    install_OpenRTM-aist
    install_openhrp3
    if [ "$INTERNAL_MACHINE" -eq 0 ] && [ "$DIST_VER" = "14.04" ]; then
	install_octomap
    fi
    install_hrpsys-base
    install_HRP2
    install_HRP2KAI
    install_HRP5P
    install_sch-core
    install_hmc2
    install_hrpsys-humanoid
    install_hrpsys-private
    install_state-observation
    install_hrpsys-state-observation
    if [ "$ENABLE_SAVEDBG" -eq 1 ]; then
	install_savedbg
    fi
    if [ "$BUILD_TRAP_FPE" -eq 1 ]; then
	install_trp-fpe
    fi
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
	install_choreonoid
    else
	install_flexiport
	install_hokuyoaist
	install_rtchokuyoaist
    fi

    packsrc $built_dirs
    $SUDO cp robot-sources.tar.bz2 $PREFIX/share/

    echo "add the following line to your .bashrc"
    echo "source $DRCUTIL/setup.bash"
    echo "export PATH=$PREFIX/bin:\$PATH" > $DRCUTIL/setup.bash
    echo "export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/ext/lib$ARCH_BITS/release:\$LD_LIBRARY_PATH" >> $DRCUTIL/setup.bash
    echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig" >> $DRCUTIL/setup.bash
    echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH" >> $DRCUTIL/setup.bash
else
    if [ $1 = "OpenRTM-aist" ]; then
	install_OpenRTM-aist
    elif [ $1 = "openhrp3" ]; then
	install_openhrp3
    elif [ $1 = "octomap" ]; then
	install_octomap
    elif [ $1 = "hrpsys-base" ]; then
	install_hrpsys-base
    elif [ $1 = "HRP2" ]; then
	install_HRP2
    elif [ $1 = "HRP2KAI" ]; then
	install_HRP2KAI
    elif [ $1 = "HRP5P" ]; then
	install_HRP5P
    elif [ $1 = "sch-core" ]; then
	install_sch-core
    elif [ $1 = "hmc2" ]; then
	install_hmc2
    elif [ $1 = "hrpsys-humaonid" ]; then
	install_hrpsys-humanoid
    elif [ $1 = "hrpsys-private" ]; then
	install_hrpsys-private
    elif [ $1 = "state-observation" ]; then
	install_state-observation
    elif [ $1 = "hrpsys-state-observation" ]; then
	install_hrpsys-state-observation
    elif [ $1 = "savedbg" ]; then
	install_savedbg
    elif [ $1 = "frap-fpe" ]; then
	install_trap-fpe
    elif [ $1 = "choreonoid" ]; then
	install_choreonoid
    elif [ $1 = "flexiport" ]; then
	install_flexiport
    elif [ $1 = "hokuyoaist" ]; then
	install_hokuyoaist
    elif [ $1 = "rtchokuyoaist" ]; then
	install_rtchokuyoaist
    else
	echo "unknown software package"
    fi
fi

