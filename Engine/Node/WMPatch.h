//
//  WMPatch.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPorts.h"

typedef enum {
	kWMPatchExecutionModeProcessor = 0, // 0 (e.g., "Math", "Image With String")
	kWMPatchExecutionModeConsumer,      // 1 (e.g., "Clear", "Billboard", "Lighting")
	kWMPatchExecutionModeProvider,	    // 2 (e.g., "Mouse", "Interaction", "XML", "Directory Scanner", "Host Info")
	kWMPatchExecutionModeRII,	        // 3 RII
} WMPatchExecutionMode;

@class WMEAGLContext;
@class WMPort;
@class WMNumberPort;
@interface WMPatch : NSObject {
@protected;
	//These don't have input at the beginning
	WMNumberPort *system_inputTime;
	//TODO: QCBooleanPort system_inputEnable;
	
	NSString *key;
    NSArray *connections;
	NSArray *children;
	NSDictionary *childrenByKey;
	id userInfo;
	
	WMPort *_enableInput;
	
	//These are set from the ivars
	NSMutableArray *inputPorts;
	NSMutableArray *outputPorts;
	
	//Render
	CFAbsoluteTime lastExecutionTime;
	
}

//Will pick the correct patch class to represent this object
+ (id)patchWithPlistRepresentation:(id)inPlist;

//Override to do your own setup
- (id)initWithPlistRepresentation:(id)inPlist;

//Call +registerToRepresentClassNames: in your subclass's +load if you want to be the decoder for a given class name
+ (void)registerToRepresentClassNames:(NSSet *)inClassNames;

- (BOOL)setPlistState:(id)inPlist;
- (id)plistState;

- (NSArray *)ivarInputPorts;
- (NSArray *)ivarOutputPorts;
- (NSArray *)systemInputPorts;
- (NSArray *)systemOutputPorts;

- (void)addInputPort:(WMPort *)inPort;
- (void)addOutputPort:(WMPort *)inPort;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSArray *connections;

@property (nonatomic, readonly) WMPatchExecutionMode executionMode;

//For now just find in children (not sub-children)
- (WMPatch *)patchWithKey:(NSString *)inKey;

- (WMPort *)inputPortWithName:(NSString *)inName;
- (WMPort *)outputPortWithName:(NSString *)inName;

//Render
- (BOOL)setup:(WMEAGLContext *)context;
- (void)enable:(WMEAGLContext *)context;
- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary*)args;
- (void)disable:(WMEAGLContext *)context;
- (void)cleanup:(WMEAGLContext *)context;

@end
