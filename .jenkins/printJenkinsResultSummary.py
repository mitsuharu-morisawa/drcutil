#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, urllib2, json
from datetime import datetime

def printLatestResults(url, job, n):
    print "|[" + job + "](http://hrg-test-results.netlify.com#" + job + ")|![Build Status](http://hrg-test-results.netlify.com/"+ job + ".svg)|",
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
            text = ""
            if result == "SUCCESS":
                color = "blue"
            elif result == "UNSTABLE":
                color = "yellow"
                try:
                    r = urllib2.urlopen(builds[i]['url'] + "artifact/task_result.txt")
                    line = r.readline()
                    text = line[0:len(line)-1]
                except:
                    pass
                finally:
                    r.close()
            elif result == "FAILURE":
                color = "red"
            else:
                color = "aborted"
            print "![Jenkins Icon](http://hrg-test-results.netlify.com/images/24x24/"+ color + ".png)"+text,
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
