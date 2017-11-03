#!/usr/bin/env bash

DRCUTIL=$PWD

source config.sh
source packsrc.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR
set -E -o pipefail
if [ "$VERBOSE_SCRIPT" -eq 1 ]; then
	set -v
fi
built_dirs=

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib

cmake_install_with_option() {
    SUBDIR="$1"
    shift

    if [ ! -d "$SRC_DIR/$SUBDIR" ]; then
	return
    fi

    # check existence of the build directory
    if [ ! -d "$SRC_DIR/$SUBDIR/$BUILD_SUBDIR" ]; then
        mkdir "$SRC_DIR/$SUBDIR/$BUILD_SUBDIR"
    fi
    cd "$SRC_DIR/$SUBDIR/$BUILD_SUBDIR"

    COMMON_OPTIONS=(-DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_C_FLAGS="$CFLAGS $ASAN_CFLAGS" -DCMAKE_CXX_FLAGS="-g $CXXFLAGS $ASAN_CXXFLAGS")
    echo cmake $(printf "'%s' " "${COMMON_OPTIONS[@]}" "$@" "${CMAKE_ADDITIONAL_OPTIONS[@]}") .. | tee config.log

    cmake "${COMMON_OPTIONS[@]}" "$@" "${CMAKE_ADDITIONAL_OPTIONS[@]}" ..  2>&1 | tee -a config.log

    $SUDO make -j$MAKE_THREADS_NUMBER install 2>&1 | tee $SRC_DIR/$SUBDIR.log

    built_dirs="$built_dirs $SUBDIR"
}

install_OpenRTM-aist() {
    cd $SRC_DIR/OpenRTM-aist
    if [ ! -e configure ]; then
	./build/autogen
    fi
    # Don't use --enable-debug for RelWithDebInfo, since that disables
    # optimization in OpenRTM.  Instead attach a debug info flag to
    # CXXFLAGS.  Using -g doesn't work because OpenRTM's configure
    # removes -g from CXXFLAGS.
    if [ $BUILD_TYPE = Debug ]; then
        ENABLE_DEBUG=--enable-debug
    else
        ENABLE_DEBUG=
    fi
    CXXFLAGS+=" -g3" \
    ./configure --prefix="$PREFIX" --without-doxygen $ENABLE_DEBUG

    built_dirs="$built_dirs OpenRTM-aist"

    $SUDO make -j$MAKE_THREADS_NUMBER install "${ASAN_FLAGS[@]}" \
	| tee $SRC_DIR/OpenRTM-aist.log
}

install_openhrp3() {
    cmake_install_with_option "openhrp3" -DCOMPILE_JAVA_STUFF=OFF -DBUILD_GOOGLE_TEST="$BUILD_GOOGLE_TEST" -DOPENRTM_DIR="$PREFIX"
}

install_octomap() {
    if [ "$DIST_VER" = "14.04" ]; then
        cmake_install_with_option "octomap-$OCTOMAP_VERSION"
    fi
}

install_pcl() {
    :
}

install_hrpsys-base() {
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
	EXTRA_OPTION=(-DINSTALL_HRPIO=ON)
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
	EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=ON)
    else
	EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=OFF)
    fi
    cmake_install_with_option hmc2 -DCOMPILE_JAVA_STUFF=OFF "${EXTRA_OPTION[@]}"
}

install_hrpsys-humanoid() { 
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
	EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=ON)
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
    cmake_install_with_option savedbg -DSAVEDBG_FRONTEND_NAME=savedbg-hrp -DSAVEDBG_FRONTEND_ARGS="-v -P 'dpkg -l > dpkg' -f '$PREFIX/share/robot-sources.tar.bz2'"
}

install_trap-fpe() {
    if [ "$ENABLE_ASAN" -eq 1 ]; then
	TRAP_FPE_EXTRA_OPTION=(-DTRAP_FPE_ASAN_WORKAROUND=ON)
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
    CUSTOMIZERS=
    if [ -e $SRC_DIR/HRP2/customizer ]; then
	CUSTOMIZERS="$SRC_DIR/HRP2/customizer/HRP2Customizer;$CUSTOMIZERS"
    fi
    if [ -e $SRC_DIR/HRP5P/customizer ]; then
	CUSTOMIZERS="$SRC_DIR/HRP5P/customizer/HRP5PCustomizer;$CUSTOMIZERS"
    fi
    # FIXME?: This doesn't look right.  CMAKE_CXX_FLAGS is ignored
    # unless CMAKE_BUILD_TYPE is empty, which it is not by default.
    cmake_install_with_option "choreonoid" -DENABLE_CORBA=ON -DBUILD_CORBA_PLUGIN=ON -DBUILD_OPENRTM_PLUGIN=ON -DBUILD_PCL_PLUGIN=ON -DBUILD_OPENHRP_PLUGIN=ON -DBUILD_GRXUI_PLUGIN=ON -DBODY_CUSTOMIZERS="$CUSTOMIZERS" -DBUILD_DRC_USER_INTERFACE_PLUGIN=ON -DCMAKE_CXX_FLAGS="$CHOREONOID_CMAKE_CXX_FLAGS" -DROBOT_HOSTNAME="$ROBOT_HOSTNAME" -DBUILD_ASSIMP_PLUGIN=OFF -DBUILD_PYTHON_PLUGIN=ON -DUSE_PYBIND11=OFF -DUSE_PYTHON3=OFF

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

install_setup.bash() {
    echo "export PATH=$PREFIX/bin:\$PATH" > $DRCUTIL/setup.bash
    echo "export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/ext/lib$ARCH_BITS/release:\$LD_LIBRARY_PATH" >> $DRCUTIL/setup.bash
    echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig" >> $DRCUTIL/setup.bash
    echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH" >> $DRCUTIL/setup.bash
    echo "add the following line to you .bashrc"
    echo "source $DRCUTIL/setup.bash"
}

if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    install_$package
done

if [ $# = 0 ]; then
    install_setup.bash
    packsrc $built_dirs
    $SUDO cp robot-sources.tar.bz2 $PREFIX/share/
fi

