#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, urllib2, json
from datetime import datetime

def printLatestResults(url, job, n):
    print "|[" + job + "](http://jenkinshrg.github.io#" + job + ")|![Build Status](http://jenkinshrg.github.io/"+ job + ".svg)|",
    try:
        url = url + 'job/' + job + '/api/json?tree=builds[building,duration,number,result,timestamp,url]'
        r = urllib2.urlopen(url)
        root = json.loads(r.read())
        builds = root['builds']
    except:
        print "|"*n
    finally:
        r.close()
    for i in range(n):
        if i < len(builds):
            result = builds[i]['result']
            if result == "SUCCESS":
                color = "blue"
            elif result == "UNSTABLE":
                color = "yellow"
            elif result == "FAILURE":
                color = "red"
            else:
                color = "aborted"
            print "![Jenkins Icon](http://jenkinshrg.github.io/images/24x24/"+ color + ".png)",
        print "|",
    print 


if len(sys.argv) > 1:
    topurl = sys.argv[1]
else:
    topurl = "http://localhost:8080/"

try:
    url = topurl + 'api/json?tree=jobs[name,lastStableBuild]'
    r = urllib2.urlopen(url)
    root = json.loads(r.read())
    jobs = root['jobs']
except:
    sys.exit(1)
finally:
    r.close()

njob = 10

print "---"
print "layout: default"
print "---"
print ""
print "Last update : " + datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print ""
print "### Job Summary"
print "___"
print ""
print "|Name|Status|Latest Results"+"|"*njob
print "|---|---|"+"--|"*njob
for job in jobs:
    if job['name'] != "drcutil" and job['name'] != "drcutil-upload":
        printLatestResults(topurl, job['name'], njob)
print ""
