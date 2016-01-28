import sys

num = 0
for line in sys.stdin:
    num += 1
    if num == 2:
        position = eval(line)

if position[2] > 0.9 and position[2] < 1.1:
    print "OK"
else:
    print "NG"
