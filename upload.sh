cd ${WORKSPACE}
echo -n > artifacts.txt
echo -n > uploads.txt

DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H-%M")

upload() {
  LABEL=${1}
  FILENAME=${2}
  MIMETYPE=${3}
  TITLE=${JOB_NAME}-${BUILD_NUMBER}-${DATE}-${TIME}-${FILENAME}
  if [ -s ${FILENAME} ]; then
      URL=${BUILD_URL}artifact/${FILENAME}
      echo "${LABEL},${FILENAME},${URL}" >> artifacts.txt
      URL=$(python ${WORKSPACE}/drcutil/.jenkins/remoteBackup.py ${TITLE} ${MIMETYPE} ${FILENAME})
      echo "${LABEL},${FILENAME},${URL}" >> uploads.txt
  fi
}

wget -q -O console.log $BUILD_URL/consoleText || true

upload "BUILD" "openhrp3.log" "text/plain"
upload "BUILD" "octomap-1.6.8.log" "text/plain"
upload "BUILD" "hrpsys-base.log" "text/plain"
upload "BUILD" "HRP2.log" "text/plain"
upload "BUILD" "HRP2KAI.log" "text/plain"
upload "BUILD" "HRP2DRC.log" "text/plain"
upload "BUILD" "hmc2.log" "text/plain"
upload "BUILD" "hrpsys-humanoid.log" "text/plain"
upload "BUILD" "hrpsys-private.log" "text/plain"
upload "BUILD" "choreonoid.log" "text/plain"

upload "CONSOLE" "irex-balance-beam-auto.txt" "text/plain"
upload "IMAGE" "irex-balance-beam-auto.png" "image/png"
upload "VIDEO" "irex-balance-beam-auto.ogv" "video/ogg"

upload "CONSOLE" "testbed-terrain.txt" "text/plain"
upload "IMAGE" "testbed-terrain.png" "image/png"
upload "VIDEO" "testbed-terrain.ogv" "video/ogg"

upload "CONSOLE" "drc-valves.txt" "text/plain"
upload "IMAGE" "drc-valves.png" "image/png"
upload "VIDEO" "drc-valves.ogv" "video/ogg"

upload "CONSOLE" "drc-wall-testbed.txt" "text/plain"
upload "IMAGE" "drc-wall-testbed.png" "image/png"
upload "VIDEO" "drc-wall-testbed.ogv" "video/ogg"
