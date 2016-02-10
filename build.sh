source config.sh
cd $SRC_DIR

build_install() {
    for dir_name in $@; do
        cd "$dir_name/build"
	echo -n "building $dir_name ... "
        $SUDO make -j2 install
        cd ../../
    done
}

build_install "openhrp3" "hrpsys-base" "HRP2" "HRP2KAI" "hmc2" "hrpsys-private" "hrpsys-humanoid"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
build_install "choreonoid"
fi

