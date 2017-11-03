######## Please don't edit from here ########
case $(lsb_release -is) in
    Debian)
        DIST_KIND=debian
	DIST_FULL_VER="$(lsb_release -rs)"
	DIST_VER="${DIST_FULL_VER:0:1}"
	INTERNAL_MACHINE=1
        ;;
    Ubuntu)
        DIST_KIND=ubuntu
	DIST_VER="$(lsb_release -rs)"
        ;;
    *)
        echo 1>&2 "config.sh: error: unknown distribution: $(lsb_release -is)"
        exit 1
        ;;
esac

case $(uname -m) in
    x86_64)
        ARCH_BITS=64
        ;;
    x86|i[3-6]86)
        ARCH_BITS=32
        ;;
    *)
        echo 1>&2 "config.sh: error: unknown architecture: $(uname -m)"
        exit 1
        ;;
esac

BUILD_GOOGLE_TEST=ON

err_report() {
    echo "Error on line $2:$1"
    echo "Stopping the script $(basename "$3")."
}


ASAN_CXXFLAGS=
ASAN_CFLAGS=

case $ENABLE_ASAN in
    1|w)
        if [ "$ENABLE_ASAN" = w ]; then
            # NB: undocumented flags, may be subject to change or deprecation.
            if "${CXX:-c++}" --version | grep -q 'clang '; then
                ASAN_WRITES_ONLY="-mllvm -asan-instrument-reads=false"
            else
                ASAN_WRITES_ONLY="--param asan-instrument-reads=0"
            fi
        else
            ASAN_WRITES_ONLY=
        fi
        ASAN_CXXFLAGS="-g3 -fsanitize=address $ASAN_WRITES_ONLY"
        ASAN_CFLAGS="-g3 -fsanitize=address $ASAN_WRITES_ONLY"
        ASAN_LDFLAGS="-g3 -fsanitize=address $ASAN_WRITES_ONLY"
        # Report, but don't fail on, leaks in program samples during build.
        export LSAN_OPTIONS="exitcode=0"
        ;;
    0)
        ASAN_CXXFLAGS=
        ASAN_CFLAGS=
        ASAN_LDFLAGS=
        ;;
esac

if [ "$ENABLE_ASAN" != 0 ]; then
    # For autoconf-based packages, sanitizer flags should NOT be
    # passed into configure because they interfere with detecting the
    # flags needed for pthreads, causing problems later on.  They are
    # instead collected in a dedicated array to be passed into make.
    ASAN_FLAGS=(CXXFLAGS="$ASAN_CXXFLAGS" CFLAGS="$ASAN_CFLAGS")
else
    ASAN_FLAGS=()
fi
