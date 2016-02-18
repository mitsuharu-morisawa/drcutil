source config.sh

pull_source() {
    for dir_name in $@; do
	echo $dir_name
        cd "$dir_name"
	git pull
        cd ..
    done
}

cd $SRC_DIR

pull_source openhrp3 hrpsys-base hmc2 hrpsys-humanoid

echo HRP2
cd HRP2
git pull
cd ..

echo HRP2KAI
cd HRP2KAI
git pull
cd ..

echo hrpsys-private
cd hrpsys-private
git pull
cd ..

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
echo choreonoid
cd choreonoid
GIT_SSL_NO_VERIFY=1 git pull
echo choreonoid/ext/hrpcnoid
cd ext/hrpcnoid
git pull
cd ../../..
fi



