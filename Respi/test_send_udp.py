#!/usr/bin/env python
# UDP Client - udpclient.py
# code by www.cppblog.com/jerryma
import sys
from socket import *

s = socket(AF_INET, SOCK_DGRAM)
s.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
s.setsockopt(SOL_SOCKET, SO_BROADCAST, 1)

data = "asdf";
# print ">>> ",
# data = sys.stdin.readline().strip()
s.sendto(data, ('255.255.255.255', 9527))
buf = s.recv(2048)
print "Server replies: ", buf