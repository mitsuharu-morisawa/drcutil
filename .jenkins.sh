echo $JENKINS_URL
echo $JOB_NAME
echo $BUILD_NUMBER
echo $WORKSPACE

if [ ! -v JOB_NAME ]; then
    JOB_NAME=debug
fi

if [ ! -v WORKSPACE ]; then
    WORKSPACE=$HOME/workspace/$JOB_NAME
    mkdir -p $WORKSPACE
    cd $WORKSPACE
fi

upload() {
  sudo pip install google-api-python-client
  source $HOME/Documents/jenkinshrg/scripts/env.sh
  bash -xe ./upload.sh || true
  awk -F, '{print $2"\t"$3"\t"}' $WORKSPACE/artifacts.txt > $WORKSPACE/artifacts_email.txt
  awk -F, '{print $2"\t"$3"\t"}' $WORKSPACE/jenkins-artifacts.txt > $WORKSPACE/jenkins-artifacts_email.txt
}

trap upload EXIT

cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh
sudo apt-get update
sudo apt-get -y install lsb-release
source config.sh

if [ ! -e $SRC_DIR ]; then
    mkdir $SRC_DIR
    sudo apt-get -y install git wget
    $HOME/Documents/jenkinshrg/install/credential.sh
    bash -xe ./getsource.sh
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    sed -i -e 's/apt-get /apt-get -y /g' $SRC_DIR/openhrp3/util/installPackages.sh
    sed -i -e 's/exit 1/exit 0/g' $SRC_DIR/openhrp3/util/installPackages.sh
    sed -i -e 's/apt-get /apt-get -y /g' $SRC_DIR/choreonoid/misc/script/install-requisites-ubuntu-14.04.sh
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
    bash -xe ./setupenv.sh
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg
    fi
    sudo apt-get -y install libgtest-dev
    bash -xe ./install.sh
    cp $SRC_DIR/*.log $WORKSPACE
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    mkdir -p $HOME/.config/Choreonoid
    cp $WORKSPACE/drcutil/.config/Choreonoid.conf $HOME/.config/Choreonoid
    sed -i -e "s/vagrant\/src/$USER\/workspace\/$JOB_NAME\/src/g" $HOME/.config/Choreonoid/Choreonoid.conf
    sed -i -e "s/vagrant\/openrtp/$USER\/workspace\/$JOB_NAME\/openrtp/g" $HOME/.config/Choreonoid/Choreonoid.conf
    fi
fi

source .bashrc
bash -xe ./diff.sh
cat $SRC_DIR/*.diff > $WORKSPACE/changes.txt
awk -F, '{print $1"\t"$3"\t"}' $WORKSPACE/changes.txt > $WORKSPACE/changes_email.txt

if [ -s $WORKSPACE/changes.txt ]; then
    #bash -xe ./update.sh
    bash -xe ./checkout.sh
    bash -xe ./build.sh
    cp $SRC_DIR/*.log $WORKSPACE
fi

if [ "$1" = "test" ] || [ "$1" = "all" ]; then
if [ -s $WORKSPACE/changes.txt ]; then
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ -z "$DISPLAY" ]; then
    sudo apt-get -y install lcov
    sudo sed -i -e 's/lcov_branch_coverage = 0/lcov_branch_coverage = 1/g' /etc/lcovrc
    sudo pip install lcov_cobertura
    #sudo pip install nose
    #sudo pip install unittest-xml-reporting
    #sudo pip install coverage
    bash -xe ./test.sh
    bash -xe ./coverage.sh
fi
fi
fi
fi

if [ "$1" = "task" ] || [ "$1" = "all" ]; then
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ -n "$DISPLAY" ]; then
    sudo apt-get -y install xautomation imagemagick recordmydesktop
    cp -r openrtp $WORKSPACE
    if [ "$2" = "walk" ] || [ "$2" = "all" ]; then
    bash -xe ./task.sh HRP2DRC jenkinshrg 620 170 530 220 120
    fi
    if [ "$2" = "terrain" ] || [ "$2" = "all" ]; then
    bash -xe ./task.sh HRP2DRC testbed-terrain 620 170 530 220 300
    fi
    if [ "$2" = "valve" ] || [ "$2" = "all" ]; then
    bash -xe ./task.sh HRP2DRC drc-valves 870 1000 760 1050 120 valve_left q
    fi
    if [ "$2" = "wall" ] || [ "$2" = "all" ]; then
    #bash -xe ./task.sh HRP2DRC drc-wall-testbed 640 170 550 220 480 tool waistAbsTransform
    bash -xe ./task.sh HRP2DRC drc-wall-testbed 640 170 550 220 480
    fi
    if [ "$2" = "balancebeam" ] || [ "$2" = "all" ]; then
    bash -xe ./task.sh HRP2DRC irex-balance-beam-auto 640 170 550 220 210
    fi
fi
fi
fi

#if [ "$1" = "analysis" ] || [ "$1" = "all" ]; then
#if [ -s $WORKSPACE/changes.txt ]; then
#if [ "$INTERNAL_MACHINE" -eq 0 ]; then
#if [ -z "$DISPLAY" ]; then
#    sudo apt-get -y install valgrind kcachegrind
#    bash -xe ./analysis.sh
#fi
#fi
#fi
#fi

if [ "$1" = "inspection" ] || [ "$1" = "all" ]; then
if [ -s $WORKSPACE/changes.txt ]; then
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ -z "$DISPLAY" ]; then
    sudo apt-get -y install cppcheck
    #sudo apt-get -y install cccc
    bash -xe ./inspection.sh
fi
fi
fi
fi
