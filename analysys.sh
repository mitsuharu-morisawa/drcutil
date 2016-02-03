cd ${WORKSPACE}
valgrind --verbose --tool=memcheck --leak-check=full --show-reachable=no --undef-value-errors=no --track-origins=no --child-silent-after-fork=no --trace-children=no --gen-suppressions=no --xml=yes --xml-file=valgrind.xml src/openhrp3/build/bin/testEigen3d || true
#valgrind --verbose --tool=massif src/openhrp3/build/bin/testEigen3d || true
#valgrind --verbose --tool=callgrind src/openhrp3/build/bin/testEigen3d || true

killall -9 openhrp-model-loader || true
openhrp-model-loader &
LOADER=$(jobs -p %+)
valgrind --verbose --tool=memcheck --leak-check=full --show-reachable=no --undef-value-errors=no --track-origins=no --child-silent-after-fork=no --trace-children=no --gen-suppressions=no --xml=yes --xml-file=valgrind.xml hrpsys-simulator `pkg-config --variable=prefix hrpsys-base`/share/hrpsys/samples/PA10/PA10simulation.xml -nodisplay -exit-on-finish || true
kill -9 $LOADER || true
wait $LOADER || true
rm -f rtc*.log
