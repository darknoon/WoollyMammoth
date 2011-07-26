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

+ (NSString *)category;
{
    return WMPatchCategoryNetwork;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass(self)]];
	[pool drain];
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
    
    outputAccelX.value = x;
    outputAccelY.value = y;
    outputAccelZ.value = z;
 }
-(void) OscMsaAccelerometer:(OscMessage *)msg { 

    // accelerometer put out by the MSA remote App
    
    float x = msg->getArg(0)._fvalue;
    float y = msg->getArg(1)._fvalue;
    float z = msg->getArg(2)._fvalue;

    NSLog(@"WMOsc OscMsaAccelerometer x:%.2f y:%.2f z:%.2f ",x,y,z);
     
    outputAccelX.value = x;
    outputAccelY.value = y;
    outputAccelZ.value = z;
    
 }

- (BOOL)setup:(WMEAGLContext *)context {
    _receiver.setup(3333);
	return YES;
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args {
    
    OscReceiver::_oscMessages.flipMessageDoubleBuffer();
    OscMessage *msg;
    
    while ((msg = _receiver.getNextMessage()) != NULL) {

        if (msg->_address=="/accxyz") { 
            
            [self OscAccxyz:msg];
        }
        else if (msg->_address=="/msaremote/accelerometer") { 
            
            [self OscMsaAccelerometer:msg];
        }
        else { 
             
            [self OscReceiverLog:msg];
        }
        delete msg;
    }
    return true;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	//TODO:
}

@end
