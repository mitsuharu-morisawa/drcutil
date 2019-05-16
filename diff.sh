source config.sh
cd $SRC_DIR

fetch_log() {
    for dir_name in $@; do
	if [ ! -e $dir_name ]; then
	    continue
	fi
        cd "$dir_name"
        echo -n > $SRC_DIR/${dir_name}.diff
        URL=$(git config --get remote.origin.url)
	if [ -e $WORKSPACE/$dir_name.rev ]; then
	    LOCAL_ID=$(cat $WORKSPACE/$dir_name.rev)
	else
            LOCAL_ID=$(git log -1 HEAD --pretty=format:"%H")
	fi
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
	if [ -v WORKSPACE ]; then
            echo $(git log -1 HEAD --pretty=format:"%H") > $WORKSPACE/$dir_name.rev
	fi
        cd ..
    done
}

fetch_log_nolink() {
    for dir_name in $@; do
	if [ ! -e $dir_name ]; then
	    continue
	fi
        cd "$dir_name"
        echo -n > $SRC_DIR/${dir_name}.diff
        URL=$(git config --get remote.origin.url)
	if [ -e $WORKSPACE/$dir_name.rev ]; then
	    LOCAL_ID=$(cat $WORKSPACE/$dir_name.rev)
	else
            LOCAL_ID=$(git log -1 HEAD --pretty=format:"%H")
	fi
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
	if [ -v WORKSPACE ]; then
            echo $(git log -1 HEAD --pretty=format:"%H") > $WORKSPACE/$dir_name.rev
	fi
        cd ..
    done
}

fetch_log_nolink_noverify() {
    for dir_name in $@; do
	if [ ! -e $dir_name ]; then
	    continue
	fi
        cd "$dir_name"
        echo -n > $SRC_DIR/${dir_name}.diff
        #URL=$(git config --get remote.origin.url)
        URL=https://github.com/s-nakaoka/choreonoid.git
	if [ -e $WORKSPACE/$dir_name.rev ]; then
	    LOCAL_ID=$(cat $WORKSPACE/$dir_name.rev)
	else
            LOCAL_ID=$(git log -1 HEAD --pretty=format:"%H")
	fi
        GIT_SSL_NO_VERIFY=1 git fetch
        git log origin HEAD --pretty=format:"%H,%h" | while read line
        do
            REMOTE_ID=$(echo "${line}" | cut -d "," -f 1)
            if [ $REMOTE_ID == $LOCAL_ID ]; then
                break
            fi
            SHORT_ID=$(echo "${line}" | cut -d "," -f 2)
            #echo "${dir_name},$SHORT_ID," >> $SRC_DIR/${dir_name}.diff
            #echo "${dir_name},$SHORT_ID,${URL%.git}/commit/$REMOTE_ID" >> $SRC_DIR/${dir_name}.diff
	    echo "${dir_name},$SHORT_ID,https://www.choreonoid.org/redmine/projects/choreonoid/repository/revisions/$REMOTE_ID/diff" >> $SRC_DIR/${dir_name}.diff
        done
	if [ -v WORKSPACE ]; then
            echo $(git log -1 HEAD --pretty=format:"%H") > $WORKSPACE/$dir_name.rev
	fi
        cd ..
    done
}

fetch_log "openhrp3" "hrpsys-base" "state-observation" "sch-core" "HRP2" "HRP2KAI" "HRP5P" "hrpsys-private" "hrpsys-state-observation" "hmc2" "hrpsys-humanoid is-jaxa"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    fetch_log "choreonoid"
    fetch_log "trap-fpe"

    if [ -e choreonoid/ext/hrpcnoid ]; then
	cd choreonoid/ext
	fetch_log "hrpcnoid"
	cd ../..
    fi

    if [ -e choreonoid/ext/takenaka ]; then
	cd choreonoid/ext
	fetch_log "takenaka"
	cd ../..
    fi

else
    fetch_log "flexiport" "hokuyoaist" "rtchokuyoaist"
fi
