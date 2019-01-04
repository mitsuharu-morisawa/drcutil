#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, json, os
from datetime import datetime

def printLatestResults(job, n):
    print "|<a href=\"" + job + ".html\">"+job+"</a>|",
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
            print "<a href=\""+result['url']+"\"><img src=\"images/24x24/"+color+".png\" alt=\""+color+".png\" title=\""+color+".png\"></a>"+text,
        print "|",
    print 

njob = 10

print "---"
print "layout: default"
print "---"

print "Last update : " + datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print ""
print "### Job Summary"
print "___"
print ""
print "{:class=\"table table-bordered\"}"
print "|Name|Latest Results"+"|"*njob
print "|---|"+"--|"*njob
for job in sys.argv[1:]:
    if job != "drcutil" and job != "drcutil-upload":
        printLatestResults(job, njob)
print ""
