check_core(){
    if [ -e core ]; then
	echo bt | gdb choreonoid core
	rm -f core
    fi
}

trap check_core EXIT

cd ${WORKSPACE}

PROJECT=${1}
TASK=${2}
AUTOPOSX=${3}
AUTOPOSY=${4}
OKPOSX=${5}
OKPOSY=${6}
WAIT=${7}
TARGET=${8}
PORT=${9}

ulimit -c unlimited
killall -9 openhrp-model-loader || true
killall -9 choreonoid || true
killall -9 recordmydesktop || true
cd ${WORKSPACE}/openrtp/share/hrpsys/samples/${PROJECT}
rm -f core
rm -f task_result.txt
rm -rf PointCloud
CNOID_TASK_TRY_FULL_AUTO_MODE=1 choreonoid ${TASK}.cnoid --start-simulation &
CHOREONOID=$(jobs -p %+)

sleep 3

WINDOWSID=$(xwininfo -display :0 -name "${TASK} - Choreonoid" | grep 'id: 0x' | grep -Eo '0x[a-z0-9]+')

recordmydesktop --windowid ${WINDOWSID} --display :0 --no-sound --overwrite -o ${WORKSPACE}/task.ogv 2>&1 > /dev/null &
RECORDMYDESKTOP=$(jobs -p %+)

sleep 17

if [ -e ${WORKSPACE}/drcutil/.jenkins/${TASK}-setTargetPos.py ]; then
    python ${WORKSPACE}/drcutil/.jenkins/${TASK}-setTargetPos.py
fi

FREE_BEFORE=$(free -m | awk 'NR==3 { print $3 }')
PS_BEFORE=$(ps -F $CHOREONOID | awk 'NR==2 { print $6 }')

xte -x :0 "mousemove ${AUTOPOSX} ${AUTOPOSY}" && xte "mouseclick 1"
sleep 1
xte -x :0 "mousemove ${OKPOSX} ${OKPOSY}" && xte "mouseclick 1"

for ((i=0; i<${WAIT}; i++)); do
    if [ -e task_result.txt ]; then
	echo "task completion is detected at $i[s]"
	break
    fi
    sleep 1
done

PS_AFTER=$(ps -F $CHOREONOID | awk 'NR==2 { print $6 }')
FREE_AFTER=$(free -m | awk 'NR==3 { print $3 }')
if [ "$PS_BEFORE" != "" ] && [ "$PS_AFTER" != "" ]; then
    PS_CHANGE=$(expr $PS_AFTER - $PS_BEFORE)
    echo 'used,change' > $WORKSPACE/choreonoid.csv
    echo $PS_AFTER,$PS_CHANGE >> $WORKSPACE/choreonoid.csv
fi
if [ "$FREE_BEFORE" != "" ] && [ "$FREE_AFTER" != "" ]; then
    FREE_CHANGE=$(expr $FREE_AFTER - $FREE_BEFORE)
    echo 'used,change' > $WORKSPACE/system.csv
    echo $FREE_AFTER,$FREE_CHANGE >> $WORKSPACE/system.csv
fi

import -display :0 -window ${WINDOWSID} ${WORKSPACE}/task.png 2>&1 > /dev/null
kill -2 $RECORDMYDESKTOP || true
wait $RECORDMYDESKTOP || true

python ${WORKSPACE}/drcutil/.jenkins/getRobotPos.py | tee ${WORKSPACE}/${TASK}-getRobotPos.txt
RESULT=$(cat ${WORKSPACE}/${TASK}-getRobotPos.txt | python ${WORKSPACE}/drcutil/.jenkins/${TASK}-checkRobotPos.py)
echo "RESULT: ${RESULT}"
if [ "${RESULT}" = "OK" ] && [ "${TARGET}" != "" ]; then
  python ${WORKSPACE}/drcutil/.jenkins/getTargetPos.py ${TARGET} ${PORT} | tee ${WORKSPACE}/${TASK}-getTargetPos.txt
  RESULT=$(cat ${WORKSPACE}/${TASK}-getTargetPos.txt | python ${WORKSPACE}/drcutil/.jenkins/${TASK}-checkTargetPos.py ${VR})
  echo "RESULT: ${RESULT}"
fi

RED=$(convert ${WORKSPACE}/task.png -format %c histogram:info: | grep red | cut -d: -f 1 | sed -e "s/ //g")
echo "Red: ${RED}"
if [ ${RED} -gt 300000 ]; then
    EMA="EMERGENCY"
else
    EMA="NORMAL"
fi
echo "EMA: ${EMA}"

kill -9 $CHOREONOID || true
wait $CHOREONOID || true

echo ${RESULT} > ${WORKSPACE}/task_result.txt

JUNIT=${WORKSPACE}/${TASK}.xml
echo "<testsuite tests='1'>" > ${JUNIT}
if [ "${RESULT}" = "OK" ] && [ "${EMA}" = "NORMAL" ]; then
    echo "<testcase name='${TASK}' classname='choreonoid' />" >> ${JUNIT}
else
    echo "<testcase name='${TASK}' classname='choreonoid'><failure message='${RESULT}'>${EMA}</failure></testcase>" >> ${JUNIT}
fi
echo "</testsuite>" >> ${JUNIT}
