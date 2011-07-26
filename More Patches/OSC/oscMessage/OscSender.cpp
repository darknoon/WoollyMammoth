/*
 OscMessage -- Open Sound Control message wrapper for oscpack
 http://www.muse.com/tr3
 
 Copyright (c) 2010 Warren Stringer <warren@muse.com>
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files
 (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 Any person wishing to distribute modifications to the Software is
 requested to send the modifications to the original developer so that
 they can be incorporated into the canonical version.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include "OscSender.h"
#include "UdpSocket.h"
#include <assert.h>

OscSender::OscSender() {
}
OscSender::~OscSender() {
}
void OscSender::setup(std::string host, int port) {
    
	socket = new UdpTransmitSocket(IpEndpointName(host.c_str(), port));
}
void OscSender::sendBundle(OscBundle& bundle) {
    
	static const int OutBufSize = 32768;
	char buffer[OutBufSize];
	osc::OutboundPacketStream stream(buffer, OutBufSize);
    
	addBundle(bundle, stream);
    
	socket->Send(stream.Data(), stream.Size());
}
void OscSender::sendMessage(OscMessage& msg) {
    
	static const int OutBufSize = 16384;
	char buffer[OutBufSize];
    osc::OutboundPacketStream stream(buffer, OutBufSize);
    
	stream << osc::BeginBundleImmediate;
	addMessage(msg, stream);
	stream << osc::EndBundle;
    
	socket->Send(stream.Data(), stream.Size());
}
void OscSender::addBundle(OscBundle& bundle, osc::OutboundPacketStream& stream) {
    
	stream << osc::BeginBundleImmediate;
    
	for (int i=0; i < (int)bundle._bundles.size(); i++) {
        
		addBundle(bundle._bundles[i], stream);
	}
	for (int i=0; i < (int)bundle._messages.size(); i++) {
        
		addMessage(bundle._messages[i], stream);
	}
	stream << osc::EndBundle;
}
void OscSender::addMessage(OscMessage& msg, osc::OutboundPacketStream& stream) {
    
    stream << osc::BeginMessage(msg._address.c_str());
    
    int size =  msg._oscArgs.size();
    
	for (int i=0; i<size; ++i) {
        
        OscArg&arg = msg.getArg(i);
        
        switch (arg._oscArgType) {
                
            case kOscArgType_Int32:  stream << (int32_t)     arg; break;
            case kOscArgType_Float:  stream << (float)       arg; break;
            case kOscArgType_String: stream << ((std::string)arg).c_str(); break;
            default: fprintf(stderr, "unknown argument type:%i\n", arg._oscArgType);
		}
	}
	stream << osc::EndMessage;
}