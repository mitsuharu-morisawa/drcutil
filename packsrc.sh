revs () {
    orig_wd="$PWD"
    find -L "$@" -type d \( -name .git -o -name .svn \) | while read repo
    do
        dir=$(dirname "$repo")
        echo "========================================"
        echo -n "$dir"
        echo -en '\t'
        case $repo in
            */.git)
                cd "$dir" || continue
                git log | head -n 1 || echo "err"
                git --no-pager diff
                ;;
            */.svn)
                cd "$dir" || continue
                svnversion || echo "err"
                svn diff
        esac
        cd "$orig_wd"
    done
}

if ! [ -d $SRC_DIR ]; then
    echo 1>&2 "packsrc.sh: error: \$SRC_DIR not set"
    echo 1>&2 "don't invoke packsrc.sh directly"
    exit 1
fi

packsrc () {
    echo "packing source trees"
    cd $SRC_DIR
    revs "$@" > revisions 2>&1
    { find $@  \(  \! \( -iwholename "*/.git*" -prune  -o  -iwholename "*/.svn*" -prune  -o -iwholename "./$BUILD_SUBDIR/" -prune -o  -exec test -e '{}/CMakeCache.txt' \; -prune -o  -name '*.o' \
      -o -name '*.lo' -o -name '*.a' -o -name '*.la' \) -a -type f \) -print0;
    for d in $*; do \
              [ -f "$d/config.log" ] \
                  && printf "$d/config.log\0"; \
              [ -f "$d/$BUILD_SUBDIR/cmake.log" ] \
                  && printf  "$d/$BUILD_SUBDIR/cmake.log\0"; \
              [ -f "$d/$BUILD_SUBDIR/CMakeCache.txt" ] \
                  && printf  "$d/$BUILD_SUBDIR/CMakeCache.txt\0"; \
              printf "$d.log\0"; \
    done;
    printf "revisions\0" ; } \
    | tar -jcf "robot-sources.tar.bz2" --null -T -
    rm -f revisions
}
