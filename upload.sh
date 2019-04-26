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
	  #URL=$(python ${WORKSPACE}/drcutil/.jenkins/upload_video.py --title=${TITLE} --file=${FILENAME} --privacyStatus=unlisted)
	  :
      else
          size=$(stat -c %s $FILENAME)
          if [ $size -gt 100000000 ]; then
              URL="too big"
          else
	      URL=$(python ${WORKSPACE}/drcutil/.jenkins/remoteBackup.py ${TITLE} ${MIMETYPE} ${FILENAME})
          fi
      fi
      echo "${LABEL},${FILENAME},${URL}" >> uploads.txt
  fi
}

# for file in $(ls *.log); do
#     upload "BUILD" $file "text/plain"
# done
# upload "BUILD" "hmc_log.tar.bz2" "application/x-gzip"
# upload "BUILD" "SelfCollision.txt" "text/plain"
# upload "IMAGE" "task.png" "image/png"
# upload "VIDEO" "task.ogv" "video/ogg"
