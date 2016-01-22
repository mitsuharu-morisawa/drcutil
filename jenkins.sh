cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh

bash -xe ./getsource.sh

bash -xe ./setupenv.sh

bash -xe ./install.sh

source env.sh

#bash -xe ./update.sh
bash -xe ./checkout.sh
bash -xe ./build.sh
