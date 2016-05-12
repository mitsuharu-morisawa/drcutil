rm -f $WORKSPACE/*.txt
rm -f $WORKSPACE/*.log
rm -f $WORKSPACE/*.png
rm -f $WORKSPACE/*.ogv
rm -f $WORKSPACE/*.csv
rm -f $WORKSPACE/*.xml

upload() {
    wget -q -O $WORKSPACE/console.log $BUILD_URL/consoleText || true
    sudo apt-get -y install python-pip python-dev
    sudo pip install google-api-python-client
    bash -e ./upload.sh || true
    awk -F, '{print $2"\t"$3"\t"}' $WORKSPACE/artifacts.txt > $WORKSPACE/artifacts_email.txt
    awk -F, '{print $2"\t"$3"\t"}' $WORKSPACE/uploads.txt > $WORKSPACE/uploads_email.txt
}

trap upload EXIT

cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh
sudo apt-get update || true #ignore checksum error
sudo apt-get -y install lsb-release
source config.sh

sudo apt-get -y install git wget
if [ -e $SRC_DIR ]; then
    rm -f $SRC_DIR/*.diff
    bash -e ./diff.sh
    cat $SRC_DIR/*.diff > $WORKSPACE/changes.txt
else
    echo -n > $WORKSPACE/changes.txt
fi
awk -F, '{print $1"\t"$3"\t"}' $WORKSPACE/changes.txt > $WORKSPACE/changes_email.txt

if [ "$1" = "build" ]; then
    rm -fr $WORKSPACE/src
    rm -fr $WORKSPACE/openrtp
fi

if [ ! -e $SRC_DIR ]; then
    mkdir $SRC_DIR
    bash -e ./getsource.sh
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    sed -i -e 's/apt-get /apt-get -y /g' $SRC_DIR/openhrp3/util/installPackages.sh
    sed -i -e 's/exit 1/exit 0/g' $SRC_DIR/openhrp3/util/installPackages.sh
    sed -i -e 's/apt-get /apt-get -y /g' $SRC_DIR/choreonoid/misc/script/install-requisites-ubuntu-$UBUNTU_VER.sh
    else
    sed -i -e 's/apt-get /apt-get -y /g' $SRC_DIR/openhrp3/util/installPackages.sh
    sed -i -e 's/exit 1/exit 0/g' $SRC_DIR/openhrp3/util/installPackages.sh
    sed -i -e "s/add-apt-repository -y ppa:hrg\/daily/add-apt-repository -y 'deb http:\/\/ppa.launchpad.net\/hrg\/daily\/ubuntu trusty main'/g" $SRC_DIR/openhrp3/util/pkg_install_ubuntu.sh
    sed -i -e "s/libeigen3-dev/#libeigen3-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost1.54-dev/#libboost1.54-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-filesystem1.54-dev/#libboost-filesystem1.54-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-program-options1.54-dev/#libboost-program-options1.54-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-regex1.54-dev/#libboost-regex1.54-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-signals1.54-dev/#libboost-signals1.54-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-thread1.54-dev/#libboost-thread1.54-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/collada-dom-dev/#collada-dom-dev/g" $SRC_DIR/openhrp3/util/packages.list.ubuntu.14.04
    fi
fi

if [ ! -e $PREFIX ]; then
    mkdir $PREFIX
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    sudo apt-get -y install software-properties-common
    else
    sudo apt-get -y install python-software-properties
    fi
    bash -e ./setupenv.sh
    bash -e ./install.sh
fi

source .bashrc

if [ -s $WORKSPACE/changes.txt ]; then
    #bash -e ./update.sh
    bash -e ./checkout.sh
    bash -e ./build.sh
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ -z "$DISPLAY" ]; then
    sudo apt-get -y install lcov
    sudo sed -i -e 's/lcov_branch_coverage = 0/lcov_branch_coverage = 1/g' /etc/lcovrc
    sudo apt-get -y install python-pip
    sudo pip install lcov_cobertura
    #sudo pip install nose
    #sudo pip install unittest-xml-reporting
    #sudo pip install coverage
    rm -f $SRC_DIR/*/build/Testing/*/Test.xml
    bash -e ./test.sh
    bash -e ./coverage.sh
    #sudo apt-get -y install valgrind kcachegrind
    #bash -e ./analysis.sh
    sudo apt-get -y install cppcheck
    #sudo apt-get -y install cccc
    bash -e ./inspection.sh
    fi
    fi
fi

if [ "$1" = "task" ]; then
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ -n "$DISPLAY" ]; then
    sudo apt-get -y install xautomation imagemagick recordmydesktop
    mkdir -p $HOME/.config/Choreonoid
    cp $WORKSPACE/drcutil/.config/Choreonoid.conf $HOME/.config/Choreonoid
    sed -i -e "s/vagrant\/src/$USER\/workspace\/$JOB_NAME\/src/g" $HOME/.config/Choreonoid/Choreonoid.conf
    sed -i -e "s/vagrant\/openrtp/$USER\/workspace\/$JOB_NAME\/openrtp/g" $HOME/.config/Choreonoid/Choreonoid.conf
    bash -e ./task.sh $2 $3 $4 $5 $6 $7 $8 $9 ${10}
fi
fi
fi
