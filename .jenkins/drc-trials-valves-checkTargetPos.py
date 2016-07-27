import sys
import math

num = 0
for line in sys.stdin:
    num += 1
    if num == 2:
        radian = eval(line)

if math.fabs(radian[0] + math.pi) < 0.3:
    print "OK"
else:
    print "NG"
