cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh

bash -xe ./getsource.sh
sed -i -e 's/apt-get /apt-get -y /g' ${WORKSPACE}/src/openhrp3/util/installPackages.sh
sed -i -e 's/exit 1/exit 0/g' ${WORKSPACE}/src/openhrp3/util/installPackages.sh
sed -i -e 's/apt-get /apt-get -y /g' ${WORKSPACE}/src/choreonoid/misc/script/install-requisites-ubuntu-14.04.sh

bash -xe ./setupenv.sh

bash -xe ./install.sh

source env.sh

#bash -xe ./update.sh
bash -xe ./checkout.sh
bash -xe ./build.sh
