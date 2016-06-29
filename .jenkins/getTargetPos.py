import rtm, OpenHRP
import sys

rtm.nsport = 2809
rtm.initCORBA()

tgt = rtm.findRTC(sys.argv[1])
data = rtm.readDataPort(tgt.port(sys.argv[2]))
print data.data
