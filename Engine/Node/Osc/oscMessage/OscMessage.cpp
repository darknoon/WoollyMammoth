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

#include "OscMessage.h"
#include <iostream>
#include <assert.h>

static OscArg* OscArgNil = new OscArg();

OscMessage::OscMessage() {
}

OscMessage::~OscMessage() {
	clear();
}

void OscMessage::clear() {
    
	for ( unsigned int i=0; i < _oscArgs.size(); ++i) {
	
        delete _oscArgs[i];
    }
	_oscArgs.clear();
	_address = "";
}


OscArg& OscMessage::getArg(unsigned int index) const {
    
    if (index < _oscArgs.size()) {
        
        return *_oscArgs[index];
    }
    else {
         fprintf(stderr,"OscMessage::getArg index %d out of bounds\n", index );
        return *OscArgNil;
    }
}
       
OscMessage& OscMessage::copy( const OscMessage& msg ) {

	_address = msg._address;    
	_host    = msg._host;
	_port    = msg._port;

    int size =  msg._oscArgs.size();    
	for ( int i=0; i<size; ++i ) {
        
        OscArg*arg = new OscArg(msg.getArg(i));
        _oscArgs.push_back(arg);
    }
	return *this;
}
