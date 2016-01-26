cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh

sudo apt-get update
sudo apt-get -y install git lsb-release wget libgtest-dev

source config.sh
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
sudo apt-get -y install software-properties-common
else
sudo apt-get -y install python-software-properties
fi

${HOME}/Documents/jenkinshrg/install/credential.sh

rm -fr $SRC_DIR
rm -fr $PREFIX

mkdir $SRC_DIR
mkdir $PREFIX

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

bash -xe ./setupenv.sh
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
sudo sed -i -e 's/giopMaxMsgSize = 2097152/giopMaxMsgSize = 2147483648/g' /etc/omniORB.cfg
fi

bash -xe ./install.sh
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
mkdir -p $HOME/.config/Choreonoid
cp ${WORKSPACE}/drcutil/Choreonoid.conf $HOME/.config/Choreonoid
sed -i -e "s/vagrant\/src/${USER}\/workspace\/${JOB_NAME}\/src/g" $HOME/.config/Choreonoid/Choreonoid.conf
sed -i -e "s/vagrant\/openrtp/${USER}\/workspace\/${JOB_NAME}\/openrtp/g" $HOME/.config/Choreonoid/Choreonoid.conf
fi

source env.sh

#bash -xe ./update.sh
bash -xe ./checkout.sh
bash -xe ./build.sh
