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
   math.fabs(rotation[1]) < 0.1:
    if math.fabs(position[0] - 2.5) < 0.2 and math.fabs(position[1] - -3.25) < 0.2:
        print "OK"
    else:
        print "STOP"
else:
    print "FALL"
