cd ${WORKSPACE}
cppcheck --enable=all --inconclusive --xml --xml-version=2 --force src 2> cppcheck.xml
#cccc $(find src -name "*.cpp" -o -name "*.cxx" -o -name "*.h" -o -name "*.hpp" -o -name "*.hxx") --outdir=.cccc
