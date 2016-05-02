cd ${WORKSPACE}

rm -fr jenkinshrg.github.io
git clone --branch master --single-branch https://github.com/jenkinshrg/jenkinshrg.github.io.git
cd jenkinshrg.github.io

JENKINS_URL=http://jenkinshrg.a01.aist.go.jp/

python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResultSummary.py ${JENKINS_URL} > index.md

REPORT_JOBS="drcutil-build-32 drcutil-build-64 drcutil-task-balancebeam drcutil-task-terrain drcutil-task-valve drcutil-task-wall hrp5p-task-terrain hrp2kai-task-door"

for REPORT_JOB in ${REPORT_JOBS}
do
    wget -q -O ${WORKSPACE}/jenkinshrg.github.io/${REPORT_JOB}.svg ${JENKINS_URL}/job/${REPORT_JOB}/badge/icon
    python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResult.py ${REPORT_JOB} ${JENKINS_URL} >> index.md
done

git add --all
git commit -m "update report"
git push origin master
