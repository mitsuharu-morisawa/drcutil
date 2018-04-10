#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, urllib2, json, base64
from datetime import datetime

def urlread(url, username, password):
    request = urllib2.Request(url)
    base64string = base64.encodestring('%s:%s' % (username, password)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % base64string) 
    return urllib2.urlopen(request)

def printLatestResults(url, username, passowrd, job, n):
    print "|[[" + job + "]]|",
    try:
        url = url + 'job/' + job + '/api/json?tree=builds[building,duration,number,result,timestamp,url]'
        r = urlread(url, username, password)
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
                    r = urlread(builds[i]['url'] + "artifact/task_result.txt", username, password)
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
            print "!["+color+"](images/"+ color + ".png)"+text,
        print "|",
    print 


if len(sys.argv) > 1:
    topurl = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
else:
    topurl = "http://localhost:8080/"
    username = "user"
    passowrd = "passwd"

try:
    url = topurl + 'api/json?tree=jobs[name,lastStableBuild]'
    r = urlread(url, username, passowrd)
    root = json.loads(r.read())
    jobs = root['jobs']
except:
    sys.exit(1)
finally:
    r.close()

njob = 10

print "Last update : " + datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print ""
print "### Job Summary"
print "___"
print ""
print "|Name|Latest Results"+"|"*njob
print "|---|"+"--|"*njob
for job in jobs:
    if job['name'] != "drcutil" and job['name'] != "drcutil-upload":
        printLatestResults(topurl, username, password, job['name'], njob)
print ""
