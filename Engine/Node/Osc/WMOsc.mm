//
//  WMOsc.m
//  Tr3Osc
//
//  Created by Warren Stringer on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WMOsc.h"
#import "OscReceiver.h"
#import "WMIndexPort.h"
#import "WMNumberPort.h"

@implementation WMOsc

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"WMOsc"]];
	[pool drain];
}

-(id) init {
    
    self = [super init];
    
    _receiver.setup(3333);
    return self;
}

-(void) OscReceiverLog:(OscMessage *)msg {
    
    string status;
    status = msg->_address + " ";
    
    int size =  msg->_oscArgs.size();
    for ( int i=0; i<size; i++ ) {
        
        OscArg&arg =  msg->getArg(i);
        
        //status += " " + arg.getTypeName() + ":";
        
        const char *buf= (const char*)malloc(128);
        
        switch (arg._oscArgType) {
                
            case kOscArgType_Int32:  { sprintf((char*)buf,"%i",  arg._ivalue);            status += buf; break; }
            case kOscArgType_Float:  { sprintf((char*)buf,"%.2f",arg._fvalue);            status += buf; break; }
            case kOscArgType_String: { sprintf((char*)buf,"%s",  arg._svalue->c_str());   status += buf; break; }
            default: break;
        }
        status += " ";
    }
    NSLog(@"%s",status.c_str());    
}

-(void) OscAccxyz:(OscMessage *)msg { 

    // accelerometer put out by the TouchOsc App
    
    float x = msg->getArg(0)._fvalue;
    float y = msg->getArg(1)._fvalue;
    float z = msg->getArg(2)._fvalue;
    
    accelX.value = x;
    accelY.value = y;
    accelZ.value = z;
 }
-(void) OscMsaAccelerometer:(OscMessage *)msg { 

    // not really an Osc message but using the same port - put out by the MSA remote
    
    float x = msg->getArg(0)._fvalue;
    float y = msg->getArg(1)._fvalue;
    float z = msg->getArg(2)._fvalue;

    NSLog(@"WMOsc OscMsaAccelerometer x:%.2f y:%.2f z:%.2f ",x,y,z);
     
    accelX.value = x;
    accelY.value = y;
    accelZ.value = z;
    
 }
- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args {
    
    OscReceiver::_oscMessages.flipMessageDoubleBuffer();
    OscMessage *msg;

    while ((msg = _receiver.getNextMessage()) != NULL) {

        if      (msg->_address=="/accxyz")                  { [self OscAccxyz:msg];}
        else if (msg->_address=="/msaremote/accelerometer") { [self OscMsaAccelerometer:msg];}
        else                                                { [self OscReceiverLog:msg];}
        delete msg;
    }
    return true;
}

@end
