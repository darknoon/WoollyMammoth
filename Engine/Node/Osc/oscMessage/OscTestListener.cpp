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

#include "ofConstants.h"
#include "ofMath.h"
#include "ofUtils.h"
#include "ofTypes.h"
#include "Osc.h"

#define PORT 3333
OscReceiver	receiver;

void OscTestListenerSetup() {
    
    receiver.setup( PORT );
}
int OscTestListenerLoop(){
    
    receiver._oscMessages.flipMessageDoubleBuffer();
    OscMessage *msg;
    while((msg = receiver.getNextMessage()) != NULL) {
        
        string status;
        status = msg->_address + " ";
        
        int size = msg->_oscArgs.size();
        for ( int i=0; i<size; i++ ) {
            
            OscArg&arg = msg->getArg(i);
            
            //status += " " + arg.getTypeName() + ":";
            
            const char *buf= (const char*)malloc(128);
            
            switch (arg._oscArgType) {
                    
                case kOscArgType_Int32:  { sprintf((char*)buf,"%i",arg._ivalue);            status += buf; break; }
                case kOscArgType_Float:  { sprintf((char*)buf,"%.2f",arg._fvalue);          status += buf; break; }
                case kOscArgType_String: { sprintf((char*)buf,"%s",arg._svalue->c_str());   status += buf; break; }
                default: break;
            }
            status += " ";
        }
        delete msg;
        fprintf(stderr, "%s\n",status.c_str());
    }
    return true;
}
