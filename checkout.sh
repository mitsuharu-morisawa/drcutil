#!/bin/bash

source config.sh

pull_source() {
    for dir_name in $@; do
	if [ -e $dir_name ]; then
	    PREV_DIR=$PWD
            cd "$dir_name"
	    if [ -e .svn ]; then
		echo $dir_name
		svn update
	    else
		BRANCH=`git branch --contains HEAD`
		echo "$dir_name (${BRANCH:2})"
		git pull
	    fi
            cd $PREV_DIR
	fi
    done
}

cd $SRC_DIR

pull_source OpenRTM-aist openhrp3 hrpsys-base sch-core hmc2 hrpsys-private hrpsys-humanoid HRP2 HRP2KAI HRP5P state-observation hrpsys-state-observation

if [ "$ENABLE_SAVEDBG" -eq 1 ]; then
    pull_source savedbg
fi
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    GIT_SSL_NO_VERIFY=1 pull_source choreonoid
    pull_source choreonoid/ext/hrpcnoid
    pull_source trap-fpe
else
    pull_source flexiport hokuyoaist rtchokuyoaist
fi



