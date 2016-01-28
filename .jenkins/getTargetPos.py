from omniORB import CORBA, any, cdrUnmarshal, cdrMarshal
import RTC, OpenRTM, SDOPackage, RTM
from OpenRTM import CdrData, OutPortCdr, InPortCdr
import rtm, time
import OpenHRP
import sys

def getClassNameOfData(port):
    pprof = port.get_port_profile()
    for prop in pprof.properties:
        if prop.name == "dataport.data_type":
            return any.from_any(prop.value)
            break
    return None

def connectWithDataPort(port):
    nv1 = SDOPackage.NameValue("dataport.interface_type", any.to_any("corba_cdr"))
    nv2 = SDOPackage.NameValue("dataport.dataflow_type", any.to_any("Pull"))
    nv3 = SDOPackage.NameValue("dataport.subscription_type", any.to_any("flush"))
    con_prof = RTC.ConnectorProfile("connector0", "", [port], [nv1, nv2, nv3])
    ret, prof = port.connect(con_prof)
    if ret != RTC.RTC_OK:
        print("failed to connect")
        return None
    else:
        return prof

def readDataFromConnector(prof, classname, timeout=1.0):
    for p in prof.properties:
        # print(p.name)
        if p.name == 'dataport.corba_cdr.outport_ior':
            ior = any.from_any(p.value)
            obj = rtm.orb.string_to_object(ior)
            outport = obj._narrow(OutPortCdr)
            tm = 0
            while tm < timeout:
                try:
                    ret, data = outport.get()
                    if ret == OpenRTM.PORT_OK:
                        tokens = classname.split(':')
                        if len(tokens) == 3:  # for 1.1?
                            classname = tokens[1].replace('/', '.')
                        return rtm.cdr2data(data, classname)
                except:
                    pass
                time.sleep(0.1)
                tm = tm + 0.1

    return None

rtm.nsport = 2809
rtm.initCORBA()

tgt = rtm.findRTC(sys.argv[1])
klass = getClassNameOfData(tgt.port(sys.argv[2]))

conprof = connectWithDataPort(tgt.port(sys.argv[2]))
data = readDataFromConnector(conprof, klass, 1.0)
print data.data
