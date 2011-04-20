//
//  WMPatch.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DNEAGLContext;
@class WMPort;
@class WMNumberPort;
@interface WMPatch : NSObject {
	//These don't have input at the beginning
	WMNumberPort *system_inputTime;
	//TODO: QCBooleanPort system_inputEnable;
	
	NSString *key;
    NSArray *connections;
	NSArray *children;
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

@property (nonatomic, copy) NSString *key;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSArray *connections;

//For now just find in children (not sub-children)
- (WMPatch *)patchWithKey:(NSString *)inKey;

- (WMPort *)inputPortWithName:(NSString *)inName;
- (WMPort *)outputPortWithName:(NSString *)inName;

//Render
- (BOOL)execute:(DNEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;

@end
