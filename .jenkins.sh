if [ ! -v JOB_NAME ]; then
    JOB_NAME=debug
fi

if [ ! -v WORKSPACE ]; then
    WORKSPACE=${HOME}/workspace/${JOB_NAME}
    cd ${WORKSPACE}
fi

upload() {
  sudo pip install google-api-python-client
  source ${HOME}/Documents/jenkinshrg/scripts/env.sh
  bash -xe ./upload.sh || true
  awk -F, '{print $2"\t"$3"\t"}' ${WORKSPACE}/artifacts.txt > ${WORKSPACE}/artifacts_email.txt
  awk -F, '{print $2"\t"$3"\t"}' ${WORKSPACE}/jenkins-artifacts.txt > ${WORKSPACE}/jenkins-artifacts_email.txt
  rm -fr jenkinshrg.github.io
  git clone https://github.com/jenkinshrg/jenkinshrg.github.io.git
  cd jenkinshrg.github.io
  bash -xe .jenkins.sh || true
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
    ${HOME}/Documents/jenkinshrg/install/credential.sh
    bash -xe ./getsource.sh
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    sed -i -e 's/apt-get /apt-get -y /g' ${WORKSPACE}/src/openhrp3/util/installPackages.sh
    sed -i -e 's/exit 1/exit 0/g' ${WORKSPACE}/src/openhrp3/util/installPackages.sh
    sed -i -e 's/apt-get /apt-get -y /g' ${WORKSPACE}/src/choreonoid/misc/script/install-requisites-ubuntu-14.04.sh
    else
    sed -i -e 's/apt-get /apt-get -y /g' ${WORKSPACE}/src/openhrp3/util/installPackages.sh
    sed -i -e 's/exit 1/exit 0/g' ${WORKSPACE}/src/openhrp3/util/installPackages.sh
    sed -i -e "s/add-apt-repository -y ppa:hrg\/daily/add-apt-repository -y 'deb http:\/\/ppa.launchpad.net\/hrg\/daily\/ubuntu trusty main'/g" ${WORKSPACE}/src/openhrp3/util/pkg_install_ubuntu.sh
    sed -i -e "s/libeigen3-dev/#libeigen3-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost1.54-dev/#libboost1.54-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-filesystem1.54-dev/#libboost-filesystem1.54-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-program-options1.54-dev/#libboost-program-options1.54-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-regex1.54-dev/#libboost-regex1.54-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-signals1.54-dev/#libboost-signals1.54-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/libboost-thread1.54-dev/#libboost-thread1.54-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
    sed -i -e "s/collada-dom-dev/#collada-dom-dev/g" ${WORKSPACE}/src/openhrp3/util/packages.list.ubuntu.14.04
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
    cp ${WORKSPACE}/src/*.log ${WORKSPACE}
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    mkdir -p $HOME/.config/Choreonoid
    cp ${WORKSPACE}/drcutil/.config/Choreonoid.conf $HOME/.config/Choreonoid
    sed -i -e "s/vagrant\/src/${USER}\/workspace\/${JOB_NAME}\/src/g" $HOME/.config/Choreonoid/Choreonoid.conf
    sed -i -e "s/vagrant\/openrtp/${USER}\/workspace\/${JOB_NAME}\/openrtp/g" $HOME/.config/Choreonoid/Choreonoid.conf
    fi
fi

source .bashrc
bash -xe ./diff.sh
cat ${WORKSPACE}/src/*.diff > ${WORKSPACE}/changes.txt
awk -F, '{print $1"\t"$3"\t"}' ${WORKSPACE}/changes.txt > ${WORKSPACE}/changes_email.txt

if [ -s ${WORKSPACE}/changes.txt ]; then
    #bash -xe ./update.sh
    bash -xe ./checkout.sh
    bash -xe ./build.sh
    cp ${WORKSPACE}/src/*.log ${WORKSPACE}
    if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ -z "${DISPLAY}" ]; then
        sudo apt-get -y install lcov
        sudo sed -i -e 's/lcov_branch_coverage = 0/lcov_branch_coverage = 1/g' /etc/lcovrc
        sudo pip install lcov_cobertura
        #sudo pip install nose
        #sudo pip install unittest-xml-reporting
        #sudo pip install coverage
        sudo apt-get -y install valgrind kcachegrind
        sudo apt-get -y install cppcheck
        #sudo apt-get -y install cccc
        bash -xe ./test.sh
        cd ${WORKSPACE}
        #lcov --capture --initial --directory . --output-file coverage.info
        lcov --capture --directory . --output-file coverage.info
        lcov --remove coverage.info '/usr/*' --output-file coverage.info
        lcov --remove coverage.info 'src/openhrp3/hrplib/hrpUtil/test*.cpp' --output-file coverage.info
        lcov --zerocounters --directory .
        python /usr/local/lib/python2.7/dist-packages/lcov_cobertura.py coverage.info
        genhtml --branch-coverage --legend --output-directory .coverage coverage.info
        #cd ${WORKSPACE}
        #valgrind --verbose --tool=memcheck --leak-check=full --xml=yes --xml-file=valgrind.xml src/openhrp3/build/bin/testEigen3d || true
        #valgrind --verbose --tool=massif src/openhrp3/build/bin/testEigen3d || true
        #valgrind --verbose --tool=callgrind src/openhrp3/build/bin/testEigen3d || true

        #killall -9 openhrp-model-loader || true
        #openhrp-model-loader &
        #LOADER=$(jobs -p %+)
        #valgrind --verbose --tool=memcheck --leak-check=full --xml=yes --xml-file=valgrind.xml hrpsys-simulator `pkg-config --variable=prefix hrpsys-base`/share/hrpsys/samples/PA10/PA10simulation.xml -nodisplay -exit-on-finish || true
        #kill -9 $LOADER || true
        #wait $LOADER || true
        #rm -f rtc*.log
        cd ${WORKSPACE}
        cppcheck --enable=all --inconclusive --xml --xml-version=2 --force src 2> cppcheck.xml
        #cccc $(find src -name "*.cpp" -o -name "*.cxx" -o -name "*.h" -o -name "*.hpp" -o -name "*.hxx") --outdir=.cccc
    fi
    fi
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ -n "${DISPLAY}" ]; then
    sudo apt-get -y install xautomation imagemagick recordmydesktop
    cp -r openrtp ${WORKSPACE}
    if [ "${1}" = "walk" ] || [ "${1}" = "" ]; then
    bash -xe ./task.sh HRP2DRC jenkinshrg 620 170 530 220 120
    fi
    if [ "${1}" = "terrain" ] || [ "${1}" = "" ]; then
    bash -xe ./task.sh HRP2DRC testbed-terrain 620 170 530 220 300
    fi
    if [ "${1}" = "valve" ] || [ "${1}" = "" ]; then
    bash -xe ./task.sh HRP2DRC drc-valves 870 1000 760 1050 90 valve_left q
    fi
    if [ "${1}" = "wall" ] || [ "${1}" = "" ]; then
    #bash -xe ./task.sh HRP2DRC drc-wall-testbed 640 170 550 220 450 tool waistAbsTransform
    bash -xe ./task.sh HRP2DRC drc-wall-testbed 640 170 550 220 450
    fi
    if [ "${1}" = "balancebeam" ] || [ "${1}" = "" ]; then
    bash -xe ./task.sh HRP2DRC irex-balance-beam-auto 640 170 550 220 180
    fi
fi
fi
