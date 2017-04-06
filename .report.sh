cd ${WORKSPACE}

rm -fr netlify-site
git clone --branch master --single-branch git@bitbucket.org:jenkinshrg/netlify-site.git
cd netlify-site

JENKINS_URL=http://jenkinshrg.a01.aist.go.jp/

python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResultSummary.py ${JENKINS_URL} > index.md

REPORT_JOBS="$(python ${WORKSPACE}/drcutil/.jenkins/getJobs.py ${JENKINS_URL})"

for REPORT_JOB in ${REPORT_JOBS}
do
    wget -q -O ${WORKSPACE}/netlify-site/${REPORT_JOB}.svg ${JENKINS_URL}/job/${REPORT_JOB}/badge/icon
    python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResult.py ${REPORT_JOB} ${JENKINS_URL} >> index.md
done

#git checkout --orphan report-new
git add --all
git commit -m "update report"
#git branch -D master
#git branch -m master
#git push -f origin master
git push origin master
