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
      if [ "$LABEL" = "VIDEO" ]; then
	  URL=$(python ${WORKSPACE}/drcutil/.jenkins/upload_video.py --title=${TITLE} --file=${FILENAME} --privacyStatus=unlisted)
      else
	  URL=$(python ${WORKSPACE}/drcutil/.jenkins/remoteBackup.py ${TITLE} ${MIMETYPE} ${FILENAME})
      fi
      echo "${LABEL},${FILENAME},${URL}" >> uploads.txt
  fi
}

upload "BUILD" "console.log" "text/plain"
upload "BUILD" "setupenv.log" "text/plain"
upload "BUILD" "install.log" "text/plain"
upload "BUILD" "build.log" "text/plain"
upload "BUILD" "task.log" "text/plain"
upload "BUILD" "SelfCollision.txt" "text/plain"
upload "BUILD" operation*.log "text/plain"
upload "IMAGE" "task.png" "image/png"
upload "VIDEO" "task.ogv" "video/ogg"
