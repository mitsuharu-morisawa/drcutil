import sys

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

if abs(rotation[0]) < 0.1 and abs(rotation[1]) < 0.1:
    print "OK"
else:
    print "FALL"
