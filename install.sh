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

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=
WARNINGS="-w -Wno-c++11-narrowing -Wno-return-type -Wno-error=vla"

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

    if [ "$USE_CLANG" -eq 1 ] && [ "$SUBDIR" != "choreonoid" ]; then
        echo -e "\n==============\nUsing clang to build...\n==============\n"
        WARNINGS="-w -Wno-c++11-narrowing -Wno-return-type -Wno-error=vla"
        CMAKE_C_COMPILER_OPT=clang
        CMAKE_CXX_COMPILER_OPT=clang++
        CMAKE_C_FLAGS_OPT="-shared -fPIC $CFLAGS ${SAN_CFLAGS[@]} $WARNINGS"
        CMAKE_CXX_FLAGS_OPT="-g -shared -fPIC -std=c++11 -fdelayed-template-parsing $WARNINGS $CXXFLAGS ${SAN_CXXFLAGS[@]}"
    else
        echo -e "\n==============\nUsing default compiler to build...\n==============\n"
        CMAKE_C_COMPILER_OPT=${COMPILER_CC}
        CMAKE_CXX_COMPILER_OPT=${COMPILER_CPP}
        CMAKE_C_FLAGS_OPT="$CFLAGS ${SAN_CFLAGS[@]}"
        CMAKE_CXX_FLAGS_OPT="-g $CXXFLAGS ${SAN_CXXFLAGS[@]}"
    fi   

    COMMON_OPTIONS=(-DCMAKE_C_COMPILER="$CMAKE_C_COMPILER_OPT" -DCMAKE_C_FLAGS="$CMAKE_C_FLAGS_OPT" -DCMAKE_CXX_COMPILER="$CMAKE_CXX_COMPILER_OPT" -DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS_OPT" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON )

    echo cmake $(printf "'%s' " "${COMMON_OPTIONS[@]}" "$@" "${CMAKE_ADDITIONAL_OPTIONS[@]}") .. | tee cmake.log

    cmake "${COMMON_OPTIONS[@]}" "$@" "${CMAKE_ADDITIONAL_OPTIONS[@]}" ..  2>&1 | tee -a cmake.log

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
    if [ "$USE_CLANG" -eq 1 ]; then
	export CXX=clang++
	export CC=clang
    fi
    CXXFLAGS+=" -g3" \
    LIBPATH=/usr/lib/`/bin/uname -p`-linux-gnu ./configure --prefix="$PREFIX" --without-doxygen $ENABLE_DEBUG

    built_dirs="$built_dirs OpenRTM-aist"

    $SUDO make -j$MAKE_THREADS_NUMBER install "${SAN_FLAGS[@]}" \
	| tee $SRC_DIR/OpenRTM-aist.log
    if [ $OSNAME = "Darwin" ]; then
	$SUDO sed -i -e s/-export-dynamic//g $PREFIX/bin/rtm-config
    fi
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
    ROBOT_IOB_VERSION_OPTION=""
    if [ -n "$ROBOT_IOB_VERSION" ]; then
        ROBOT_IOB_VERSION_OPTION="-DROBOT_IOB_VERSION=${ROBOT_IOB_VERSION}"
    fi
    
    cmake_install_with_option hrpsys-base -DCOMPILE_JAVA_STUFF=OFF -DBUILD_KALMAN_FILTER=OFF -DBUILD_STABILIZER=OFF -DENABLE_DOXYGEN=OFF "${EXTRA_OPTION[@]}" ${ROBOT_IOB_VERSION_OPTION}
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
    EXTRA_OPTION=()
    [ "$ENABLE_ASAN" != 0 ] && EXTRA_OPTION+=(-DTRAP_FPE_ASAN_WORKAROUND=ON)
    [ "$ENABLE_TSAN" != 0 ] && EXTRA_OPTION+=(-DTRAP_FPE_TSAN_WORKAROUND=ON)
    # DynamoRIO doesn't seem to have an official install step.
    # We just unpack the distribution directly into $PREFIX.
    $SUDO tar -zxf $SRC_DIR/DynamoRIO-$DYNAMORIO_VERSION.tar.gz -C $PREFIX/share
    cmake_install_with_option trap-fpe "-DTRAP_FPE_BLACKLIST=$DRCUTIL/trap-fpe.blacklist.$DIST_KIND$DIST_VER" "-DDynamoRIO_DIR=$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/cmake" "${EXTRA_OPTION[@]}"
}

install_choreonoid() {
    CXX_FLAGS_BAK=$CXXFLAGS
    if [ "$IS_VIRTUAL_BOX" -eq 1 ]; then
      CXXFLAGS="-DJOYSTICK_DEVICE_PATH=\"/dev/input/js1\" $CXXFLAGS" #mouse integration uses /dev/input/js1 in virtualbox
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
    cmake_install_with_option "choreonoid" -DENABLE_CORBA=ON -DBUILD_CORBA_PLUGIN=ON -DBUILD_OPENRTM_PLUGIN=ON -DUSE_BUILTIN_CAMERA_IMAGE_IDL=ON -DBUILD_PCL_PLUGIN=ON -DBUILD_OPENHRP_PLUGIN=ON -DBUILD_GRXUI_PLUGIN=ON -DBODY_CUSTOMIZERS="$CUSTOMIZERS" -DBUILD_DRC_USER_INTERFACE_PLUGIN=ON -DROBOT_HOSTNAME="$ROBOT_HOSTNAME" -DBUILD_ASSIMP_PLUGIN=OFF -DBUILD_PYTHON_PLUGIN=OFF -DUSE_PYBIND11=OFF -DUSE_PYTHON3=OFF -DBUILD_BALANCER_PLUGIN=OFF -DENABLE_PYTHON=OFF -DBUILD_PYTHON_SIM_SCRIPT_PLUGIN=OFF -DBUILD_BOOST_PYTHON_MODULES=ON -DENABLE_CXX_STANDARD_17=OFF

    CXXFLAGS=$CXX_FLAGS_BAK

    mkdir -p $HOME/.config/Choreonoid
    cp $DRCUTIL/.config/Choreonoid.conf $DRCUTIL
    CHOREONOID_SHARE=`pkg-config --variable=sharedir choreonoid`
    sed -i -e "s#/home/vagrant/src#$SRC_DIR#g" $DRCUTIL/Choreonoid.conf
    sed -i -e "s#/home/vagrant/openrtp/share/choreonoid-x.y#$CHOREONOID_SHARE#g" $DRCUTIL/Choreonoid.conf
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
    if [ $OSNAME = "Darwin" ]; then
	echo "export DYLD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/ext/lib$ARCH_BITS/release:\$DYLD_LIBRARY_PATH" >> $DRCUTIL/setup.bash
    else
	echo "export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/ext/lib$ARCH_BITS/release:\$LD_LIBRARY_PATH" >> $DRCUTIL/setup.bash
    fi
    echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH" >> $DRCUTIL/setup.bash
    echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH" >> $DRCUTIL/setup.bash
    echo "export ASAN_OPTIONS=\"disable_coredump=0:unmap_shadow_on_exit=1:abort_on_error=1\"" >> $DRCUTIL/setup.bash
    if [ $OSNAME != "Darwin" ]; then
	if [ "$(lsb_release -rs)" = "14.04" ]; then
            echo "export ASAN_LIB=/usr/lib/x86_64-linux-gnu/libasan.so.0" >> $DRCUTIL/setup.bash
	elif [ "$(lsb_release -rs)" = "16.04" ]; then
            echo "export ASAN_LIB=/usr/lib/x86_64-linux-gnu/libasan.so.2" >> $DRCUTIL/setup.bash
	else
            echo "export ASAN_LIB=/usr/lib/x86_64-linux-gnu/libasan.so.4" >> $DRCUTIL/setup.bash
	fi
    fi
    
    echo "add the following line to your .bashrc"
    echo "source $DRCUTIL/setup.bash"
}

install_is-jaxa() {
    cmake_install_with_option is-jaxa
}

install_takenaka() {
    :
}

if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    install_$package
done

if [ $# = 0 ]; then
    install_setup.bash
    # packsrc $built_dirs
    # $SUDO cp robot-sources.tar.bz2 $PREFIX/share/
fi

