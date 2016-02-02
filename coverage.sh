cd ${WORKSPACE}
#lcov --capture --initial --directory . --output-file coverage.info
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '/usr/*' --output-file coverage.info
lcov --remove coverage.info 'src/openhrp3/hrplib/hrpUtil/test*.cpp' --output-file coverage.info
lcov --zerocounters --directory .
python /usr/local/lib/python2.7/dist-packages/lcov_cobertura.py coverage.info
genhtml --branch-coverage --legend --output-directory .coverage coverage.info
