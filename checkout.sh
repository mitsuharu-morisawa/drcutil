source config.sh

pull_source() {
    for dir_name in $@; do
	if [ -e $dir_name ]; then
	    echo $dir_name
            cd "$dir_name"
	    if [ -e .svn ]; then
		svn update
	    else
		git pull
	    fi
            cd ..
	fi
    done
}

cd $SRC_DIR

pull_source OpenRTM-aist openhrp3 hrpsys-base sch-core hmc2 hrpsys-private hrpsys-humanoid HRP2 HRP2KAI HRP5P state-observation hrpsys-state-observation

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    GIT_SSL_NO_VERIFY=1 pull_source choreonoid
    pull_source choreonoid/ext/hrpcnoid
else
    pull_source flexiport hokuyoaist rtchokuyoaist
fi



