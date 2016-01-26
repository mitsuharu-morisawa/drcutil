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
