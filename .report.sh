cd ${WORKSPACE}

# if [ ! -e netlify-site ]; then
#     rm -fr netlify-site
#     git clone --branch master --single-branch git@bitbucket.org:jenkinshrg/netlify-site.git
# fi
# cd netlify-site

JENKINS_URL=http://jenkinshrg.a01.aist.go.jp/

REPORT_JOBS="$(python ${WORKSPACE}/drcutil/.jenkins/getJobs.py ${JENKINS_URL}  $1 $2)"

for REPORT_JOB in ${REPORT_JOBS}
do
    python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResult.py ${REPORT_JOB} ${JENKINS_URL} $1 $2 > ${REPORT_JOB}.md
done

python ${WORKSPACE}/drcutil/.jenkins/printJenkinsResultSummary.py ${REPORT_JOBS} > index.md

#git checkout --orphan report-new
#git add --all
#git commit -m "update report"
#git branch -D master
#git branch -m master
#git push -f origin master
jekyll
scp -r _site/* jenkinshrg:/var/www/html/ci

