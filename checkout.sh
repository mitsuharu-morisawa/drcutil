source config.sh

cd $SRC_DIR

cd openhrp3
git pull
cd ..


cd hrpsys-base
git pull
cd ..


if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ "$HAVE_ATOM_ACCESS" -eq 1 ]
then
    cd HRP2
    svn update 
    cd ..

    # cd robot/HRP2SH
    # svn update 
    # cd ../..
fi
fi


cd HRP2DRC
git pull
cd ..

cd hmc2
git pull
cd ..


cd hrpsys-humanoid
git pull
cd ..


if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ "$HAVE_ATOM_ACCESS" -eq 1 ]
then
    cd hrpsys-private
    svn update
    cd ..
fi
fi


if [ "$INTERNAL_MACHINE" -eq 0 ]; then
cd choreonoid
GIT_SSL_NO_VERIFY=1 git pull
cd ext/hrpcnoid
git pull
cd ../../..
fi



