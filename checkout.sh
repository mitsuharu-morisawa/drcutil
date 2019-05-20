#!/bin/bash

source config.sh

pull_source() {
    dir_name=$1
    if [ -e $dir_name ]; then
	PREV_DIR=$PWD
        cd "$dir_name"
	if [ -e .svn ]; then
	    echo $dir_name
	    svn update 2>&1 | tee svn.log
	else
	    BRANCH=`git branch --contains HEAD`
            SREF=`git symbolic-ref HEAD -q` || true
	    echo "$dir_name (${BRANCH:2})"
            if [ ! -z $SREF ]; then
            	git submodule update --init
            	git pull
            fi
	fi
        cd $PREV_DIR
    fi
}

pull_source_choreonoid() {
    GIT_SSL_NO_VERIFY=1 pull_source choreonoid
    pull_source choreonoid/ext/hrpcnoid
    pull_source choreonoid/ext/cnoid-boost-python
    pull_source choreonoid/ext/openhrp-plugin
    pull_source choreonoid/ext/grxui-plugin
    if [ -e $SRC_DIR/choreonoid/ext/takenaka ]; then
        pull_source choreonoid/ext/takenaka
    fi
}

cd $SRC_DIR

if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    if [ $package = "choreonoid" ]; then
        pull_source_choreonoid
    else
        pull_source $package
    fi
done
