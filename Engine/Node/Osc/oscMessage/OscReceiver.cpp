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

#import "OscReceiver.h"

DoubleBufferThread<OscMessage> OscReceiver::_oscMessages;

void OscReceiver::setup(int port_) {
    
	_socket = new UdpListeningReceiveSocket(IpEndpointName(IpEndpointName::ANY_ADDRESS, port_), this);
    pthread_create(&_oscMessages._thread, NULL, &OscReceiver::startThread, (void*)_socket);
}

void* OscReceiver::startThread(void* socket_) {
    
	UdpListeningReceiveSocket* socket = (UdpListeningReceiveSocket*)socket_;
	socket->Run();
	return NULL;
}

void OscReceiver::ProcessMessage(const osc::ReceivedMessage &msg, const IpEndpointName& ipEndpointName) {

	OscMessage *oscMessage = new OscMessage();
	oscMessage->_address = msg.AddressPattern();
    
	// set the sender ip/host
	char host[IpEndpointName::ADDRESS_STRING_LENGTH];
	ipEndpointName.AddressAsString(host);
    oscMessage->_host = host;
    oscMessage->_port = ipEndpointName.port;
    
	for (osc::ReceivedMessage::const_iterator arg = msg.ArgumentsBegin(); arg != msg.ArgumentsEnd(); ++arg) {
        
		if      (arg->IsInt32())  oscMessage->_oscArgs.push_back(new OscArg((int)     arg->AsInt32Unchecked())); 
		else if (arg->IsFloat())  oscMessage->_oscArgs.push_back(new OscArg((float)   arg->AsFloatUnchecked()));
		else if (arg->IsString()) oscMessage->_oscArgs.push_back(new OscArg(          arg->AsStringUnchecked()));
		else                      fprintf(stderr, "message argument is not int, float, or string");
	}
	_oscMessages.push(oscMessage);
}

OscMessage* OscReceiver::getNextMessage() {

	OscMessage* message = _oscMessages.pop();
	return message;
}

