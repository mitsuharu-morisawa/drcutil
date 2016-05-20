import rtm
import RTC
import sys
import random
import math

rtm.nsport=2809
rtm.initCORBA()

rtc = rtm.findRTC("box")
port = rtc.port("q_ref")
q_min = -1.0
q_max = -0.5
q = q_min + (q_max - q_min)*random.random()
print "door angle = ",q
data = RTC.TimedDoubleSeq(RTC.Time(0,0), [q])
rtm.writeDataPort(port, data)
