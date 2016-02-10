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

build_install "openhrp3" "hrpsys-base"

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    build_install "HRP2"
    build_install "HRP2KAI"
fi

build_install "HRP2DRC" "hmc2" "hrpsys-humanoid"

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    build_install "hrpsys-private"
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
build_install "choreonoid"
fi

