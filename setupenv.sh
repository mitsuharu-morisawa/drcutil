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

# if [ "$DIST_KIND" = "ubuntu" ] && [ "$DIST_VER" = "14.04" ]; then
#     sudo rm -rf gcc-7.3.0
#     wget http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-7.3.0/gcc-7.3.0.tar.gz
#     tar zxvf gcc-7.3.0.tar.gz
#     cd gcc-7.3.0
#     ./contrib/download_prerequisites
#     mkdir build
#     cd build
#     ../configure --enable-languages=c,c++ --prefix=$PREFIX --disable-bootstrap --disable-multilib
#     make -j$MAKE_THREADS_NUMBER
#     $SUDO make -j$MAKE_THREADS_NUMBER install
# fi

setupenv_OpenRTM-aist() {
    if [ $OSNAME = "Darwin" ]; then
	brew install autoconf automake libtool omniorb
    else
	sudo apt-get -y install autoconf
	if [ "$DIST_VER" = "16.04" ] || [ "$DIST_VER" = "8" ] || [ "$DIST_VER" = "18.04" ]; then
            sudo apt-get -y install libtool-bin
	else
            sudo apt-get -y install libtool
	fi
    fi
}

setupenv_openhrp3() {
    if [ $OSNAME = "Darwin" ]; then
	brew install cmake eigen boost pkg-config jpeg libpng
    else
	cd $SRC_DIR/openhrp3/util
	./installPackages.sh packages.list.$DIST_KIND.$DIST_VER
	sudo apt-get -y remove openrtm-aist-dev openrtm-aist # install from source

	sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg

	if [ "$BUILD_GOOGLE_TEST" = "ON" ]; then
            sudo apt-get -y install libgtest-dev
	fi
    fi
}

setupenv_pcl() {
    if [ $OSNAME = "Darwin" ]; then
	brew install pcl
    else
	if [ "$DIST_VER" = "14.04" ]; then
	    sudo add-apt-repository -y ppa:v-launchpad-jochen-sprickerhof-de/pcl
	    sudo apt-get update || true #ignore checksum error
	    sudo apt-get -y install libpcl-all
	else
	    sudo apt-get -y --allow-unauthenticated install libpcl-dev libproj-dev
	fi
    fi
}

setupenv_octomap() {
    if [ $OSNAME = "Darwin" ]; then
	brew install octomap
    else
	if [ "$DIST_VER" = "16.04" ] || [ "$DIST_VER" = "18.04" ]; then
	    sudo apt-get -y install liboctomap-dev
	fi
    fi
}

setupenv_hrpsys-base() {
    if [ $OSNAME = "Darwin" ]; then
	brew install opencv sdl boost-python
    else
	sudo apt-get -y --force-yes install libxml2-dev libsdl-dev libglew-dev libopencv-dev libqhull-dev freeglut3-dev libxmu-dev python-dev libboost-python-dev ipython openrtm-aist-python
	if [ "$DIST_VER" != "18.04" ]; then
            sudo apt-get -y --force-yes install libcvaux-dev libhighgui-dev
	fi
    fi
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
    if [ $OSNAME = "Darwin" ]; then
	brew install doxygen
    else
	sudo apt-get -y install libboost-test-dev libboost-timer-dev
    fi
}

setupenv_hmc2() {
    if [ $OSNAME = "Darwin" ]; then
	brew install libyaml
    else
	sudo apt-get -y install libyaml-dev libncurses5-dev
    fi
}

setupenv_hrpsys-private() {
    :
}

setupenv_hrpsys-humanoid() {
    if [ $OSNAME != "Darwin" ]; then
	sudo apt-get -y install libusb-dev
    fi
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
    if [ $OSNAME = "Darwin" ]; then
	brew install gettext qt zbar
    else
	#choreonoid
	cd $SRC_DIR/choreonoid/misc/script
	./install-requisites-$DIST_KIND-$DIST_VER.sh

	#hrpcnoid
	sudo apt-get -y --allow-unauthenticated install libzbar-dev python-matplotlib
    fi
}

setupenv_is-jaxa() {
    :
}

setupenv_takenaka() {
    :
}

if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    setupenv_$package
done

