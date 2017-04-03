#!/usr/bin/env bash

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

#OpenRTM-aist
sudo apt-get -y install autoconf
if [ "$DIST_VER" = "16.04" ] || [ "$DIST_VER" = "8" ]; then
    sudo apt-get -y install libtool-bin
else
    sudo apt-get -y install libtool
fi

#openhrp3
cd $SRC_DIR/openhrp3/util
./installPackages.sh packages.list.$DIST_KIND.$DIST_VER

sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg

if [ "$BUILD_GOOGLE_TEST" = "ON" ]; then
    sudo apt-get -y install libgtest-dev
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$DIST_VER" = "14.04" ]; then
	sudo add-apt-repository -y ppa:v-launchpad-jochen-sprickerhof-de/pcl
	sudo apt-get update || true #ignore checksum error
	sudo apt-get -y install libpcl-all
    else
	sudo apt-get -y install libpcl-dev libproj-dev
	sudo apt-get -y install liboctomap-dev
    fi
fi

#hrpsys-base
sudo apt-get -y --force-yes install libxml2-dev libsdl-dev libglew-dev libopencv-dev libcvaux-dev libhighgui-dev libqhull-dev freeglut3-dev libxmu-dev python-dev libboost-python-dev ipython openrtm-aist-python

#hmc2
sudo apt-get -y install libyaml-dev libncurses5-dev

#state-observation
if [ "$DIST_KIND" = "debian" ]; then
    sudo apt-get -y install libboost-test-dev
fi

#savedbg
if [ "$ENABLE_SAVEDBG" -eq 1 ]; then
    if [ "$DIST_VER" = 14.04 ]; then
        REALPATH=realpath
    else
        REALPATH=
    fi
    sudo apt-get -y install elfutils $REALPATH
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    #choreonoid
    cd $SRC_DIR/choreonoid/misc/script
    ./install-requisites-$DIST_KIND-$DIST_VER.sh

    #hrpcnoid
    sudo apt-get -y install libzbar-dev python-matplotlib
fi

