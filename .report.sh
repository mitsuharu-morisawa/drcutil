cd ${WORKSPACE}

rm -fr hrg-ci-results.wiki
git clone https://github.com/isri-aist/hrg-ci-results.wiki.git
cd hrg-ci-results.wiki

JENKINS_URL=http://jenkinshrg.a01.aist.go.jp/

python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResultSummary.py ${JENKINS_URL} $1 $2 > index.md

REPORT_JOBS="$(python ${WORKSPACE}/drcutil/.jenkins/getJobs.py ${JENKINS_URL}  $1 $2)"

for REPORT_JOB in ${REPORT_JOBS}
do
    python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResult.py ${REPORT_JOB} ${JENKINS_URL} $1 $2 > ${REPORT_JOB}.md
done

git checkout --orphan report-new
git add --all
git commit -m "update report"
git branch -D master
git branch -m master
git push -f origin master
