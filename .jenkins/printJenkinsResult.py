#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, urllib2, json, base64
from datetime import datetime
import json,os

def urlread(url, username, password):
    request = urllib2.Request(url)
    base64string = base64.encodestring('%s:%s' % (username, password)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % base64string) 
    return urllib2.urlopen(request)

def getResultFromMasterServer(build):
    result = {}
    result['url'] = build['url']+"artifact/"
    result['timestamp'] = build['timestamp']
    result['duration'] = build['duration']
    result['building'] = build['building']
    ret = build['result']
    if ret == "UNSTABLE":
        try:
            r = urlread(build['url'] + "artifact/task_result.txt", username, password)
            line = r.readline()
            ret = line[0:len(line)-1]
        except:
            pass
        finally:
            r.close()
    result['result'] = ret
    failCount = ""
    try:
        url = build['url'] + "testReport/api/json?tree=failCount"
        r = urlread(url, username, password)
        root = json.loads(r.read())
        failCount = root['failCount']
    except:
        pass
    if failCount != "":
        failCount = str(failCount) + " err."
    ratio = ""
    try:
        url = build['url'] + "cobertura/api/json?tree=results[elements[*]]"
        r = urlread(url, username, password)
        root = json.loads(r.read())
        elements = root['results']['elements']
        n = 0
        for element in elements:
            if (n == 4):
                ratio = int(round(element['ratio']))
            n += 1;
    except:
        pass
    result['failCount'] = failCount
    ratio = ""
    try:
        url = build['url'] + "cobertura/api/json?tree=results[elements[*]]"
        r = urlread(url, username, password)
        root = json.loads(r.read())
        elements = root['results']['elements']
        n = 0
        for element in elements:
            if (n == 4):
                ratio = int(round(element['ratio']))
            n += 1;
    except:
        pass
    if ratio != "":
        ratio = str(ratio) + " %"
    result['ratio'] = ratio
    numberErrorSeverity = ""
    try:
        url = build['url'] + "cppcheckResult/api/json?tree=numberErrorSeverity"
        r = urlread(url, username, password)
        root = json.loads(r.read())
        numberErrorSeverity = root['numberErrorSeverity']
    except:
        pass
    if numberErrorSeverity != "":
        numberErrorSeverity = str(numberErrorSeverity) + " err."
    result['numberErrorSeverity'] = numberErrorSeverity
    changes = ""
    try:
        url = build['url'] + "artifact/changes.txt"
        r = urlread(url, username, password)
        line = r.readline()
        while line:
            line = line.strip()
            dirname = line.split(",")[0]
            commitid = line.split(",")[1]
            githuburl = line.split(",")[2]
            tmp = dirname + "/" + commitid
            if (githuburl != ""):
                changes += "[" + tmp + "](" + githuburl + ")" + "<br>"
            else:
                changes += tmp + "<br>"
            line = r.readline()
    except:
        pass
    result['changes'] = changes
    build_files = ""
    image_files = ""
    video_files = ""
    uploads = ""
    try:
        url = build['url'] + "artifact/uploads.txt"
        r = urlread(url, username, password)
        line = r.readline()
        while line:
            line = line.strip()
            label = line.split(",")[0]
            filename = line.split(",")[1]
            googleurl = line.split(",")[2]
            if label == "BUILD":
                build_files += "[" + filename + "](" + googleurl + ")" + "<br>"
            elif label == "IMAGE":
                tokens = googleurl.split("/")
                fileid = tokens[5]
                image_files += "<a href=\""+googleurl+"\"><img src=\"http://drive.google.com/uc?export=view&id="+fileid+"\" alt=\"task.png\" title=\"task.png\" width=400></a>"
            elif label == "VIDEO":
                video_files += "[" + filename + "](" + googleurl + ")" + "<br>"
            line = r.readline()
    except:
        pass
    uploads = build_files + image_files + video_files
    result['uploads'] = uploads
    slave = ""
    try:
        url = build['url'] + "artifact/env.txt"
        r = urlread(url, username, password)
        line = r.readline()
        slave = line[0:len(line)-1]
    except:
        pass
    result['slave'] = slave
    notes = ""
    memory_used = ""
    memory_change = ""
    try:
        url = build['url'] + "artifact/choreonoid.csv"
        r = urlread(url, username, password)
        line = r.readline()
        line = r.readline()
        line = line.strip()
        memory_used = line.split(",")[0] + "KB used" + "<br>"
        memory_change = line.split(",")[1] + "KB change" + "<br>"
    except:
        pass
    notes = memory_used + memory_change
    result['notes'] = notes
    return result

### get builds from master server ###
name = sys.argv[1]
if len(sys.argv) > 2:
    url = sys.argv[2]
    username = sys.argv[3]
    password = sys.argv[4]
else:
    url = "http://localhost:8080/"
    username = "user"
    password = "passwd"
try:
    url = url + 'job/' + name + '/api/json?tree=builds[building,duration,number,result,timestamp,url]'
    r = urlread(url, username, password)
    root = json.loads(r.read())
    builds = root['builds']
except:
    sys.exit(1)
finally:
    r.close()

### load cache ###
cacheFile = name+".json"
results = {}
if os.path.exists(cacheFile):
    f = open(cacheFile, 'r')
    results = json.load(f)
    f.close()

### update results ###
for build in builds:
    number = str(build['number'])
    if (not number in results) and (build['building'] == False):
        results[number] = getResultFromMasterServer(build)

### print results ###
cnt = 0
okcnt = 0
for build in builds:
    result = build['result']
    if result == "SUCCESS":
        okcnt += 1
    elif result == "UNSTABLE":
        pass
    elif result == "FAILURE":
        pass
    else:
        continue
    cnt += 1
if cnt > 0:
    stability = int(round(((okcnt * 1.0)/ cnt) * 100))
    if stability >= 80:
        iconUrl = "health-80plus.png"
    elif stability >= 60:
        iconUrl = "health-60to79.png"
    elif stability >= 40:
        iconUrl = "health-40to59.png"
    elif stability >= 20:
        iconUrl = "health-20to39.png"
    else:
        iconUrl = "health-00to19.png"
else:
    stability = 0
    iconUrl = "health-00to19.png"

print "---"
print "layout: default"
print "---"

print "Last update : " + datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print ""

print "#### Build Stability"

print "![Jenkins Icon](images/48x48/" + iconUrl + ")"
print str(stability) + "%"
print ""

print "#### Build History"
print ""

print "|#|Status|Time|Duration|Slave|Inspection|Test|Coverage|Changes|Logs|Notes|"
print "|---|------|----|--------|----|----------|----|--------|-------|----|-----|"

for build in builds:
    number = str(build['number'])
    if not number in results:
        continue

    result = results[number]
    ret = result['result']
    if ret == "SUCCESS":
        color = "blue"
    elif ret == "FAILURE":
        color = "red"
    elif ret == "ABORTED":
        color = "aborted"
    else:
        color = "yellow"
    failCount = result['failCount']
    ratio = result['ratio']
    numberErrorSeverity = result['numberErrorSeverity']
    changes = result['changes']
    uploads = result['uploads']
    slave = result['slave']
    notes = result['notes']
    print "|[" + number + "]("+result['url']+")|" + "![Jenkins Icon](images/24x24/"+ color + ".png)" + ret + "|" + str(datetime.fromtimestamp(result['timestamp'] / 1000).strftime("%Y/%m/%d %H:%M")) + "|" + str(result['duration'] / 60 / 1000) + " min." + "|" + slave + "|" + numberErrorSeverity + "|" + failCount + "|" + ratio + "|" + changes + "|" + uploads + "|" + notes + "|"
print ""

### save results ###
f = open(cacheFile, 'w')
json.dump(results, f)
f.close()
