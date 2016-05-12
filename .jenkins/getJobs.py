#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, urllib2, json

if len(sys.argv) > 1:
    topurl = sys.argv[1]
else:
    topurl = "http://localhost:8080/"

try:
    url = topurl + 'api/json?tree=jobs[name,lastStableBuild]'
    r = urllib2.urlopen(url)
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

