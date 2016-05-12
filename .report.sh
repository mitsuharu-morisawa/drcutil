cd ${WORKSPACE}

rm -fr jenkinshrg.github.io
git clone --branch master --single-branch https://github.com/jenkinshrg/jenkinshrg.github.io.git
cd jenkinshrg.github.io

JENKINS_URL=http://jenkinshrg.a01.aist.go.jp/

python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResultSummary.py ${JENKINS_URL} > index.md

REPORT_JOBS="$(python ${WORKSPACE}/drcutil/.jenkins/getJobs.py ${JENKINS_URL})"

for REPORT_JOB in ${REPORT_JOBS}
do
    wget -q -O ${WORKSPACE}/jenkinshrg.github.io/${REPORT_JOB}.svg ${JENKINS_URL}/job/${REPORT_JOB}/badge/icon
    python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResult.py ${REPORT_JOB} ${JENKINS_URL} >> index.md
done

git add --all
git commit -m "update report"
git push origin master
