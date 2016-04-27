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

upload "BUILD" "console.log" "text/plain"

upload "IMAGE" "irex-balance-beam-auto.png" "image/png"
upload "VIDEO" "irex-balance-beam-auto.ogv" "video/ogg"

upload "IMAGE" "testbed-terrain.png" "image/png"
upload "VIDEO" "testbed-terrain.ogv" "video/ogg"

upload "IMAGE" "drc-valves.png" "image/png"
upload "VIDEO" "drc-valves.ogv" "video/ogg"

upload "IMAGE" "drc-wall-testbed.png" "image/png"
upload "VIDEO" "drc-wall-testbed.ogv" "video/ogg"

upload "IMAGE" "drc-door.png" "image/png"
upload "VIDEO" "drc-door.ogv" "video/ogg"
