#coding=utf-8
#!/user/bin/env python
# twistedchatserver.py 22:13 2007-9-28 zhangsk
from uuid import getnode as get_mac
import time
from twisted.internet.protocol import DatagramProtocol
from twisted.internet.protocol import Factory
from twisted.protocols.basic import LineOnlyReceiver
from twisted.internet import reactor
import os, subprocess, time, signal


class Eye(LineOnlyReceiver):
    def lineReceived(self, data):
        print "%s: %s" % (self.getId(), data)
        if (data == "?capture"):
            self.transport.write("!ok/r/n")
            # self.capture_proc = subprocess.Popen("raspivid -q -n -w 720 -h 404 -fps 25 -t 100000 -o - | /root/CatEye/Respi/send %s " % self.transport.getPeer().host, shell = True, preexec_fn = os.setsid)
            self.capture_proc = subprocess.Popen("raspivid -q -n -w 480 -h 270 -fps 20 -t 100000 -o - | /root/CatEye/Respi/send %s " % self.transport.getPeer().host, shell = True, preexec_fn = os.setsid)
            print self.capture_proc.pid
        elif (data == "?stop"):
            self.transport.write("!ok/r/n")
            if (self.capture_proc):
                os.killpg(self.capture_proc.pid, signal.SIGTERM)
                self.capture_proc = None
        
    def getId(self):
        return str(self.transport.getPeer())
    
    def connectionMade(self):
        print "New connection from", self.getId()
        self.factory.addClient(self)
        
    def connectionLost(self, reason):
        print "DisConnection"
        self.factory.delClient(self)
       

class EyeFactory(Factory):
    protocol = Eye
    
    def __init__(self):
        self.clients = []
        
    def addClient(self, newclient):
        self.clients.append(newclient)
        
    def delClient(self, client):
        self.clients.remove(client)
            
            
class Discover(DatagramProtocol):
    def __init__(self):
        pass

    def startProtocol(self):
        "Called when transport is connected"
        pass

    def stopProtocol(self):
        "Called after all transport is teared down"
        pass
        
    def datagramReceived(self, data, (host, port)):
        now = time.localtime(time.time())  
        timeStr = str(time.strftime("%y/%m/%d %H:%M:%S",now)) 
        print "received %r from %s:%d at %s" % (data, host, port, timeStr)
        self.transport.write(str("!me@%s"%get_mac()), (host, 9527))


reactor.listenMulticast(9527, Discover(), listenMultiple=True)
reactor.listenTCP(9528, EyeFactory())
reactor.run()
