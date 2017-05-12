source config.sh
cd $SRC_DIR

ctest_exec() {
    for dir_name in $@; do
        cd "$dir_name/$BUILD_SUBDIR"
	echo -n "testing $dir_name ... "
        ctest --verbose --test-action Test || true
        cd ../../
    done
}

ctest_exec "openhrp3" "hrpsys-base"

ctest_exec "HRP2" "HRP2KAI"

ctest_exec "hmc2" "hrpsys-humanoid"

ctest_exec "hrpsys-private"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
ctest_exec "choreonoid"
fi
