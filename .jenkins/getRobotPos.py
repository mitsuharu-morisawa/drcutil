import rtm, OpenHRP

rtm.nsport = 2809
rtm.initCORBA()

hmc = rtm.findRTC("hmc")
data = rtm.readDataPort(hmc.port("pRes"))
pos = data.data
data = rtm.readDataPort(hmc.port("rpyRes"))
rpy = data.data
print [pos.x,pos.y,pos.z]
print [rpy.r,rpy.p,rpy.y]
