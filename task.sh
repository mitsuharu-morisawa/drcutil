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

rm -f ${TASK}.*

ulimit -c unlimited
killall -9 openhrp-model-loader || true
killall -9 choreonoid || true
cd ${WORKSPACE}/openrtp/share/hrpsys/samples/${PROJECT}
rm -f core
CNOID_TASK_TRY_FULL_AUTO_MODE=1 choreonoid ${TASK}.cnoid --start-simulation 2>&1 | tee ${WORKSPACE}/${TASK}.txt &
CHOREONOID=$(jobs -p %+)

sleep 20
WINDOWSID=$(xwininfo -display :0 -name "${TASK} - Choreonoid" | grep 'id: 0x' | grep -Eo '0x[a-z0-9]+')

recordmydesktop --windowid ${WINDOWSID} --display :0 --no-sound --overwrite -o ${WORKSPACE}/${TASK}.ogv 2>&1 > /dev/null &
RECORDMYDESKTOP=$(jobs -p %+)

xte -x :0 "mousemove ${AUTOPOSX} ${AUTOPOSY}" && xte "mouseclick 1"
sleep 1
xte -x :0 "mousemove ${OKPOSX} ${OKPOSY}" && xte "mouseclick 1"
sleep ${WAIT}

python ${WORKSPACE}/drcutil/.jenkins/getRobotPos.py | tee ${WORKSPACE}/${TASK}-getRobotPos.txt
RESULT=$(cat ${WORKSPACE}/${TASK}-getRobotPos.txt | python ${WORKSPACE}/drcutil/.jenkins/${TASK}-checkRobotPos.py)
echo "RESULT: ${RESULT}"
if [ "${TARGET}" != "" ]; then
  python ${WORKSPACE}/drcutil/.jenkins/getTargetPos.py ${TARGET} ${PORT} | tee ${WORKSPACE}/${TASK}-getTargetPos.txt
  RESULT=$(cat ${WORKSPACE}/${TASK}-getTargetPos.txt | python ${WORKSPACE}/drcutil/.jenkins/${TASK}-checkTargetPos.py ${VR})
  echo "RESULT: ${RESULT}"
fi

import -display :0 -window ${WINDOWSID} ${WORKSPACE}/${TASK}.png 2>&1 > /dev/null

RED=$(convert ${WORKSPACE}/${TASK}.png -format %c histogram:info: | grep red | cut -d: -f 1 | sed -e "s/ //g")
echo "Red: ${RED}"
if [ ${RED} -gt 300000 ]; then
    EMA="EMERGENCY"
else
    EMA="NORMAL"
fi
echo "EMA: ${EMA}"

kill -9 $CHOREONOID || true
wait $CHOREONOID || true
kill -2 $RECORDMYDESKTOP || true
wait $RECORDMYDESKTOP || true

JUNIT=${WORKSPACE}/${TASK}.xml
echo "<testsuite tests='1'>" >> ${JUNIT}
if [ "${RESULT}" = "OK" ] && [ "${EMA}" = "NORMAL" ]; then
    echo "<testcase name='${TASK}' classname='choreonoid' />" >> ${JUNIT}
else
    echo "<testcase name='${TASK}' classname='choreonoid'><failure message='${RESULT}'>${EMA}</failure></testcase>" >> ${JUNIT}
fi
echo "</testsuite>" >> ${JUNIT}
