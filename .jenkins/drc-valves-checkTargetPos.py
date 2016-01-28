import sys

num = 0
for line in sys.stdin:
    num += 1
    if num == 2:
        radian = eval(line)

if radian[0] > 3.2 and radian[0] < 3.4:
    print "OK"
else:
    print "NG"
