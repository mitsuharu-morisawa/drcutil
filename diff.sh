source config.sh
cd $SRC_DIR

update_log() {
    for dir_name in $@; do
        cd "$dir_name"
        echo -n > $SRC_DIR/${dir_name}.diff
        STATUS=$(svn status --show-updates --quiet)
        if [ "$STATUS" != "" ]; then
            echo "${dir_name},xxxxxxx," >> $SRC_DIR/${dir_name}.diff
        fi
#        svn log --quiet --incremental --revision HEAD | while read line
#        do
#            set +e
#            echo ${line} | grep "^-"
#            if [ $? -ne 0 ]; then
#                REMOTE_ID=$(echo "${line}" | cut -d "|" -f 1)
#                echo ",${REMOTE_ID}" >> $SRC_DIR/${dir_name}.diff
#            fi
#            set -e
#        done
        cd ..
    done
}

fetch_log() {
    for dir_name in $@; do
        cd "$dir_name"
        echo -n > $SRC_DIR/${dir_name}.diff
        URL=$(git config --get remote.origin.url)
        LOCAL_ID=$(git log -1 HEAD --pretty=format:"%H")
        git fetch
        git log origin HEAD --pretty=format:"%H,%h" | while read line
        do
            REMOTE_ID=$(echo "${line}" | cut -d "," -f 1)
            if [ $REMOTE_ID == $LOCAL_ID ]; then
                break
            fi
            SHORT_ID=$(echo "${line}" | cut -d "," -f 2)
            echo "${dir_name},$SHORT_ID,${URL%.git}/commit/$REMOTE_ID" >> $SRC_DIR/${dir_name}.diff
        done
        cd ..
    done
}

fetch_log_nolink() {
    for dir_name in $@; do
        cd "$dir_name"
        echo -n > $SRC_DIR/${dir_name}.diff
        URL=$(git config --get remote.origin.url)
        LOCAL_ID=$(git log -1 HEAD --pretty=format:"%H")
        git fetch
        git log origin HEAD --pretty=format:"%H,%h" | while read line
        do
            REMOTE_ID=$(echo "${line}" | cut -d "," -f 1)
            if [ $REMOTE_ID == $LOCAL_ID ]; then
                break
            fi
            SHORT_ID=$(echo "${line}" | cut -d "," -f 2)
            echo "${dir_name},$SHORT_ID," >> $SRC_DIR/${dir_name}.diff
        done
        cd ..
    done
}

fetch_log "openhrp3" "hrpsys-base"

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    update_log "HRP2"
fi

fetch_log "HRP2DRC" "hmc2" "hrpsys-humanoid"

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    update_log "hrpsys-private"
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
fetch_log_nolink "choreonoid"

cd choreonoid/ext
fetch_log "hrpcnoid"
cd ../..
fi
