#!/usr/bin/env bash


source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

if [ "$ENABLE_ASAN" -eq 1 ]; then
    BUILD_TYPE=RelWithDebInfo
    ASAN_OPTIONS="-DCMAKE_CXX_FLAGS_RELWITHDEBINFO=\"-O2 -g -DNDEBUG -fsanitize=address\" -DCMAKE_C_FLAGS_RELWITHDEBINFO=\"-O2 -g -DNDEBUG -fsanitize=address\""
else
    ASAN_OPTIONS=
fi

cmake_install_with_option() {
    # check existence of the build directory
    if [ ! -d "$SRC_DIR/$1/build" ]; then
        mkdir "$SRC_DIR/$1/build"
    fi
    cd "$SRC_DIR/$1/build"

    COMMON_OPTIONS="-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=$BUILD_TYPE"$ASAN_OPTIONS
    echo cmake $COMMON_OPTIONS

    if [ $# = 1 ]; then
        cmake $COMMON_OPTIONS ..
    else
        cmake $COMMON_OPTIONS $2 ..
    fi

    $SUDO make -j$MAKE_THREADS_NUMBER install
}

cd $SRC_DIR/OpenRTM-aist
if [ ! -e configure ]; then
    ./build/autogen
fi
if [ $BUILD_TYPE != "Release" ]; then
    EXTRA_OPTION="--enable-debug"
else
    EXTRA_OPTION=
fi
./configure --prefix=$PREFIX --without-doxygen $EXTRA_OPTION
$SUDO make -j$MAKE_THREADS_NUMBER install

cmake_install_with_option "openhrp3" "-DCOMPILE_JAVA_STUFF=OFF -DBUILD_GOOGLE_TEST=$BUILD_GOOGLE_TEST"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$UBUNTU_VER" != "16.04" ]; then
	cmake_install_with_option "octomap-$OCTOMAP_VERSION"
    fi
    EXTRA_OPTION=
else
    EXTRA_OPTION="-DINSTALL_HRPIO=OFF"
fi
cmake_install_with_option "hrpsys-base" "-DCOMPILE_JAVA_STUFF=OFF -DBUILD_KALMAN_FILTER=OFF -DBUILD_STABILIZER=OFF -DENABLE_DOXYGEN=OFF $EXTRA_OPTION"
cmake_install_with_option "HRP2" "-DROBOT_NAME=HRP2KAI"
cmake_install_with_option "HRP2KAI"
cmake_install_with_option "HRP5P"
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    EXTRA_OPTION=
else
    EXTRA_OPTION="-DGENERATE_FILES_FOR_SIMULATION=OFF"
fi
cmake_install_with_option "hmc2" "-DCOMPILE_JAVA_STUFF=OFF $EXTRA_OPTION"
cmake_install_with_option "hrpsys-humanoid" "-DCOMPILE_JAVA_STUFF=OFF $EXTRA_OPTION"
cmake_install_with_option "hrpsys-private"
cmake_install_with_option "state-observation" "-DCMAKE_INSTALL_LIBDIR=lib"
cmake_install_with_option "hrpsys-state-observation"
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$IS_VIRTUAL_BOX" -eq 1 ]; then
      CHOREONOID_CMAKE_CXX_FLAGS="\"-DJOYSTICK_DEVICE_PATH=\\\"/dev/input/js1\\\"\" $CHOREONOID_CMAKE_CXX_FLAGS" #mouse integration uses /dev/input/js1 in virtualbox
    fi
    cmake_install_with_option "choreonoid" "-DENABLE_CORBA=ON -DBUILD_CORBA_PLUGIN=ON -DBUILD_OPENRTM_PLUGIN=ON -DBUILD_PCL_PLUGIN=ON -DBUILD_OPENHRP_PLUGIN=ON -DBUILD_GRXUI_PLUGIN=ON -DBODY_CUSTOMIZERS=$SRC_DIR/HRP2/customizer/HRP2Customizer;$SRC_DIR/HRP5P/customizer/HRP5PCustomizer -DBUILD_DRC_USER_INTERFACE_PLUGIN=ON -DCMAKE_CXX_FLAGS=$CHOREONOID_CMAKE_CXX_FLAGS"
else
    cmake_install_with_option "flexiport" "-DBUILD_DOCUMENTATION=OFF"
    cmake_install_with_option "hokuyoaist" "-DBUILD_DOCUMENTATION=OFF -DBUILD_PYTHON_BINDINGS=OFF"
    cmake_install_with_option "rtchokuyoaist" "-DBUILD_DOCUMENTATION=OFF"
fi

echo "add the following environmental variable settings to your .bashrc"
echo "export PATH=$PREFIX/bin:\$PATH"
echo "export LD_LIBRARY_PATH=$PREFIX/lib:\$LD_LIBRARY_PATH"
echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig"
echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH"
