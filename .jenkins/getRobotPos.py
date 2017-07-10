import rtm, OpenHRP

rtm.nsport = 2809
rtm.initCORBA()

rh = rtm.findRTC("VirtualRobotHardware0")
data = rtm.readDataPort(rh.port("waistAbsTransform"))
pos = data.data.position
rpy = data.data.orientation
print [pos.x,pos.y,pos.z]
print [rpy.r,rpy.p,rpy.y]
