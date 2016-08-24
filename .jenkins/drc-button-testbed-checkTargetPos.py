import sys
import math

num = 0
for line in sys.stdin:
    num += 1
    if num == 2:
        angles = eval(line)

if angles[0] < -math.pi:
    print "OK"
else:
    print "NG"
