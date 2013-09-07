#coding=utf-8
#!/user/bin/env python
# twistedchatserver.py 22:13 2007-9-28 zhangsk
import time
from twisted.internet.protocol import DatagramProtocol
from twisted.internet.protocol import Factory
from twisted.protocols.basic import LineOnlyReceiver
from twisted.internet import reactor

class Eye(LineOnlyReceiver):
    def lineReceived(self, data):
        print "lineReceived"
        print "%s: %s" % (self.getId(), data)        
        
    def getId(self):
        return str(self.transport.getPeer())
    
    def connectionMade(self):
        print "New connection from", self.getId()
        self.transport.write("Welcome to the chat server, %s\n" %
            self.getId())
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
        self.transport.write(str("12121"), (host, port))



reactor.listenMulticast(9527, Discover(), listenMultiple=True)
reactor.listenTCP(9528, EyeFactory())
reactor.run()