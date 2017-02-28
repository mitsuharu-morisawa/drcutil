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
    tar -jcf "robot-sources.tar.bz2" \
        --exclude-vcs --exclude=build --exclude=.libs --exclude='*.o' \
        --exclude='*.lo' --exclude='*.a' --exclude='*.la' \
        revisions \
        "$@" \
        $(for d in $*; do \
              [ -f "$d/config.log" ] \
                  && echo "$d/config.log"; \
              [ -f "$d/build/config.log" ] \
                  && echo "$d/build/config.log"; \
              [ -f "$d/build/CMakeCache.txt" ] \
                  && echo "$d/build/CMakeCache.txt"; \
              echo "$d.log"; \
          done)
    rm -f revisions
}
