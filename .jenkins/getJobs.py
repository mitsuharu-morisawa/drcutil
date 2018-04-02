#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, urllib2, json, base64

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
    request = urllib2.Request(url)
    base64string = base64.encodestring('%s:%s' % (username, password)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % base64string) 
    r = urllib2.urlopen(request)
    root = json.loads(r.read())
    jobs = root['jobs']
    for j in jobs:
        n = j['name']
        if n != "drcutil" and n != "drcutil-upload":
            print j['name'],
    print
except:
    sys.exit(1)
finally:
    r.close()

