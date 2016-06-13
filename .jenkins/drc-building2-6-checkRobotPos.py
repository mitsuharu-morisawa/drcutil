import sys
import math

num = 0
for line in sys.stdin:
    if line.find("nan") >= 0:
        print "FALL"
        sys.exit(0)
    num += 1
    if num == 2:
        position = eval(line)
    if num == 3:
        rotation = eval(line)

if math.fabs(rotation[0]) < 0.1 and \
   math.fabs(rotation[1]) < 0.1 and \
   math.fabs(rotation[2]) < 2.0:
    if position[0] > 2.5 and position[1] < -2.5:
        print "OK"
    else:
        print "STOP"
else:
    print "FALL"
