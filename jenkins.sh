cp config.sh.sample config.sh
sed -i -e "s/HOME/WORKSPACE/g" config.sh

./getsource.sh

./setupenv.sh

./install.sh

source env

./update.sh
