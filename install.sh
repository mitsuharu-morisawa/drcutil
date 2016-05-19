#!/usr/bin/env bash


source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

cmake_install_with_option() {
    # check existence of the build directory
    if [ ! -d "$SRC_DIR/$1/build" ]; then
        mkdir "$SRC_DIR/$1/build"
    fi
    cd "$SRC_DIR/$1/build"

    if [ $# = 1 ]; then
        cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=$BUILD_TYPE ..
    else
        cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=$BUILD_TYPE $2 ..
    fi

    $SUDO make -j$MAKE_THREADS_NUMBER install
}

cmake_install_with_option "openhrp3" "-DCOMPILE_JAVA_STUFF=OFF -DBUILD_GOOGLE_TEST=$BUILD_GOOGLE_TEST"

if [ "$UBUNTU_VER" != "16.04" ]; then
   cmake_install_with_option "octomap-1.8.0"
fi

cmake_install_with_option "hrpsys-base" "-DCOMPILE_JAVA_STUFF=OFF -DBUILD_KALMAN_FILTER=OFF -DBUILD_STABILIZER=OFF"
cmake_install_with_option "HRP2" "-DROBOT_NAME=HRP2KAI"
cmake_install_with_option "HRP2KAI"
cmake_install_with_option "HRP5P"
cmake_install_with_option "hmc2" "-DCOMPILE_JAVA_STUFF=OFF"
cmake_install_with_option "hrpsys-humanoid" "-DCOMPILE_JAVA_STUFF=OFF"
cmake_install_with_option "hrpsys-private"
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
cmake_install_with_option "choreonoid" "-DENABLE_CORBA=ON -DBUILD_CORBA_PLUGIN=ON -DBUILD_OPENRTM_PLUGIN=ON -DBUILD_PCL_PLUGIN=ON -DBUILD_OPENHRP_PLUGIN=ON -DBUILD_GRXUI_PLUGIN=ON -DBODY_CUSTOMIZERS=$SRC_DIR/HRP2/customizer/HRP2Customizer;$SRC_DIR/HRP5P/customizer/HRP5PCustomizer -DBUILD_DRC_USER_INTERFACE_PLUGIN=ON"
fi

echo "add the following environmental variable settings to your .bashrc"
echo "export PATH=$PREFIX/bin:\$PATH"
echo "export LD_LIBRARY_PATH=$PREFIX/lib:\$LD_LIBRARY_PATH"
echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig"
echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH"
