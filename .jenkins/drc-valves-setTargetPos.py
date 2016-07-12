import rtm
import RTC
import sys
import random
import math

rtm.nsport=2809
rtm.initCORBA()

rtc = rtm.findRTC("valve_left")
port = rtc.port("q_ref")
q_min = 0
q_max = math.pi/2
q = q_min + (q_max - q_min)*random.random()
print "valve angle = ",q
data = RTC.TimedDoubleSeq(RTC.Time(0,0), [q])
rtm.writeDataPort(port, data)
