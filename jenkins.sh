cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh

source ./getsource.sh

source ./setupenv.sh

source ./install.sh

source env

#source ./update.sh
source ./checkout.sh
source ./build.sh
