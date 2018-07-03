#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, json, os
from datetime import datetime

def printLatestResults(job, n):
    print "|[[" + job + "]]|",
    cacheFile = job+".json"
    if not os.path.exists(cacheFile):
        print "|"*n
        return
    f = open(job+".json",'r')
    results = sorted(json.load(f).items(), key=lambda x: -int(x[0]))
    f.close()
    for i in range(n):
        if i < len(results):
            result = results[i][1]
            ret = result['result']
            text = ""
            if ret == "SUCCESS":
                color = "blue"
            elif ret == "FAILURE":
                color = "red"
            elif ret == "ABORTED":
                color = "aborted"
            else:
                color = "yellow"
                text = ret
            print "<a href=\""+result['url']+"\"><img src=\"https://github.com/isri-aist/hrg-ci-results/wiki/images/"+color+".png\" alt=\""+color+".png\" title=\""+color+".png\"></a>"+text,
        print "|",
    print 

njob = 10

print "Last update : " + datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print ""
print "### Job Summary"
print "___"
print ""
print "|Name|Latest Results"+"|"*njob
print "|---|"+"--|"*njob
for job in sys.argv[1:]:
    if job != "drcutil" and job != "drcutil-upload":
        printLatestResults(job, njob)
print ""
