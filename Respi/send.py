import os, subprocess, socket, time

pipe = subprocess.Popen("raspivid -q -n -w 720 -h 405 -fps 25 -t 10000 -o -",shell = True,stdout = subprocess.PIPE)
n = 0

address = ('192.168.119.107', 1234)
sckt = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

while True:
    s = pipe.stdout.read(1400)
    if len(s) == 0:
        time.sleep(0.01)
        n += 1
        if n > 100:
            print "sleep over 1 sec."
            n = 0
    else:
        n = 0
        sckt.sendto(s, address)
