#!/usr/bin/env bash

source config.sh

sudo apt-get -y install git subversion

get_source() {
    if [ ! -e $2 ]; then
	$1
    fi
}

cd $SRC_DIR

get_source "svn co http://svn.openrtm.org/OpenRTM-aist/branches/RELENG_1_1/OpenRTM-aist" OpenRTM-aist
get_source "git clone https://github.com/fkanehiro/openhrp3.git" openhrp3

get_source "git clone ssh://atom.a01.aist.go.jp/git/HRP2" HRP2
get_source "git clone ssh://atom.a01.aist.go.jp/git/HRP2KAI" HRP2KAI
get_source "git clone ssh://atom.a01.aist.go.jp/git/HRP5P" HRP5P
get_source "git clone ssh://atom.a01.aist.go.jp/git/hrpsys-private" hrpsys-private

get_source "git clone https://github.com/fkanehiro/hrpsys-base" hrpsys-base
get_source "git clone https://github.com/jrl-umi3218/hmc2" hmc2
get_source "git clone https://github.com/jrl-umi3218/hrpsys-humanoid" hrpsys-humanoid
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$UBUNTU_VER" != "16.04" ]; then
	get_source "wget https://github.com/OctoMap/octomap/archive/v$OCTOMAP_VERSION.tar.gz" octomap-$OCTOMAP_VERSION
	get_source "tar zxvf v$OCTOMAP_VERSION.tar.gz" octomap-$OCTOMAP_VERSION
    fi
    GIT_SSL_NO_VERIFY=1 get_source "git clone https://choreonoid.org/git/choreonoid.git" choreonoid
    cd choreonoid/ext
    get_source "git clone https://github.com/jrl-umi3218/hrpcnoid" hrpcnoid
    cd ../..
else
    get_source "git clone https://github.com/gbiggs/flexiport" flexiport
    get_source "git clone https://github.com/gbiggs/hokuyoaist" hokuyoaist
    get_source "git clone https://github.com/gbiggs/rtchokuyoaist" rtchokuyoaist
fi
