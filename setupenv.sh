#!/usr/bin/env bash

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR


cd $SRC_DIR/openhrp3/util
./installPackages.sh packages.list.ubuntu.$UBUNTU_VER

sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg

if [ "$BUILD_GOOGLE_TEST" = "ON" ]; then
    sudo apt-get -y install libgtest-dev
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$UBUNTU_VER" = "16.04" ]; then
	sudo apt-get -y install libpcl-dev libproj-dev
	sudo apt-get -y install liboctomap-dev
    else
	sudo add-apt-repository -y ppa:v-launchpad-jochen-sprickerhof-de/pcl
	sudo apt-get update || true #ignore checksum error
	sudo apt-get -y install libpcl-all
    fi
fi
#hrpsys-base
sudo apt-get -y install libxml2-dev libsdl-dev libglew-dev libopencv-dev libcvaux-dev libhighgui-dev libqhull-dev freeglut3-dev libxmu-dev python-dev libboost-python-dev ipython openrtm-aist-python
#hmc2
sudo apt-get -y install libyaml-dev libncurses5-dev

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
cd $SRC_DIR/choreonoid/misc/script
./install-requisites-ubuntu-$UBUNTU_VER.sh

#hrpcnoid
sudo apt-get -y install libzbar-dev python-matplotlib
else
cd $WORKSPACE
sudo rm -fr 3.2.5.tar.gz eigen-eigen-bdd17ee3b1b3
wget -q http://bitbucket.org/eigen/eigen/get/3.2.5.tar.gz
tar zxvf 3.2.5.tar.gz
cd eigen-eigen-bdd17ee3b1b3
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
sudo make -j$MAKE_THREADS_NUMBER install
cd ../..
sudo rm -fr 3.2.5.tar.gz eigen-eigen-bdd17ee3b1b3

sudo apt-get -y install libbz2-dev
wget -q http://sourceforge.net/projects/boost/files/boost/1.54.0/boost_1_54_0.tar.gz
tar zxvf boost_1_54_0.tar.gz
cd boost_1_54_0
./bootstrap.sh
sudo ./b2 install -j2 --prefix=/usr/local
cd ..
sudo rm -fr boost_1_54_0.tar.gz boost_1_54_0

wget -q http://sourceforge.net/projects/collada-dom/files/Collada%20DOM/Collada%20DOM%202.4/collada-dom-2.4.0.tgz
tar zxvf collada-dom-2.4.0.tgz
cd collada-dom-2.4.0
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
sudo make -j$MAKE_THREADS_NUMBER install
cd ../..
sudo rm -fr collada-dom-2.4.0.tgz collada-dom-2.4.0
fi

