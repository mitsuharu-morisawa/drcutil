#!/usr/bin/env bash

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

if [ "$DIST_KIND" = "debian" ]; then
    sudo rm -rf cmake-2.8.12
    wget https://cmake.org/files/v2.8/cmake-2.8.12.tar.gz
    tar zxvf cmake-2.8.12.tar.gz
    cd cmake-2.8.12
    ./bootstrap
    make -j$MAKE_THREADS_NUMBER
    sudo make install
    cd ../

    wget https://github.com/eigenteam/eigen-git-mirror/archive/3.2.5.tar.gz
    tar zxvf 3.2.5.tar.gz
    cd eigen-git-mirror-3.2.5
    mkdir build
    cd build
    cmake ../ -DCMAKE_INSTALL_PREFIX=$PREFIX
    sudo make install
    cd ../../
fi

setupenv_OpenRTM-aist() {
    sudo apt-get -y install autoconf
    if [ "$DIST_VER" = "16.04" ] || [ "$DIST_VER" = "8" ]; then
        sudo apt-get -y install libtool-bin
    else
        sudo apt-get -y install libtool
    fi
}

setupenv_openhrp3() {
    cd $SRC_DIR/openhrp3/util
    ./installPackages.sh packages.list.$DIST_KIND.$DIST_VER
    sudo apt-get remove openrtm-aist-dev openrtm-aist # install from source

    sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg

    if [ "$BUILD_GOOGLE_TEST" = "ON" ]; then
        sudo apt-get -y install libgtest-dev
    fi
}

setupenv_pcl() {
    if [ "$DIST_VER" = "14.04" ]; then
	sudo add-apt-repository -y ppa:v-launchpad-jochen-sprickerhof-de/pcl
	sudo apt-get update || true #ignore checksum error
	sudo apt-get -y install libpcl-all
    else
	sudo apt-get -y install libpcl-dev libproj-dev
    fi
}

setupenv_octomap() {
    if [ "$DIST_VER" = "16.04" ]; then
	sudo apt-get -y install liboctomap-dev
    fi
}

setupenv_hrpsys-base() {
    sudo apt-get -y --force-yes install libxml2-dev libsdl-dev libglew-dev libopencv-dev libcvaux-dev libhighgui-dev libqhull-dev freeglut3-dev libxmu-dev python-dev libboost-python-dev ipython openrtm-aist-python
}

setupenv_HRP2() {
    :
}

setupenv_HRP2KAI() {
    :
}

setupenv_HRP5P() {
    :
}

setupenv_sch-core() {
    :
}
    
setupenv_state-observation() {
    sudo apt-get -y install libboost-test-dev
}

setupenv_hmc2() {
    sudo apt-get -y install libyaml-dev libncurses5-dev
}

setupenv_hrpsys-private() {
    :
}

setupenv_hrpsys-humanoid() {
    sudo apt-get -y install libusb-dev
}

setupenv_hrpsys-state-observation() {
    :
}

setupenv_trap-fpe() {
    :
}

setupenv_savedbg() {
    if [ "$DIST_VER" = 14.04 ]; then
        REALPATH=realpath
    else
        REALPATH=
    fi
    sudo apt-get -y install elfutils $REALPATH
}

setupenv_choreonoid() {
    #choreonoid
    cd $SRC_DIR/choreonoid/misc/script
    ./install-requisites-$DIST_KIND-$DIST_VER.sh

    #hrpcnoid
    sudo apt-get -y install libzbar-dev python-matplotlib
}

if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    setupenv_$package
done

