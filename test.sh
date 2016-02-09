source config.sh
cd $SRC_DIR

ctest_exec() {
    for dir_name in $@; do
        cd "$dir_name/build"
        rm -f Testing/*/Test.xml
	echo -n "testing $dir_name ... "
        ctest --verbose --test-action Test || true
        cd ../../
    done
}

ctest_exec "openhrp3" "hrpsys-base"

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    ctest_exec "HRP2" "HRP2KAI"
fi

ctest_exec "HRP2DRC" "hmc2" "hrpsys-humanoid"

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    ctest_exec "hrpsys-private"
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
ctest_exec "choreonoid"
fi
