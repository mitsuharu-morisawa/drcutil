import rtm, OpenHRP

rtm.nsport = 2809
rtm.initCORBA()

rg = rtm.findRTC("rg")
data = rtm.readDataPort(rg.port("event"))
print data.actual.p
print data.actual.rpy
