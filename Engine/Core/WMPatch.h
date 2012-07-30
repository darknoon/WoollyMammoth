//
//  WMPatch.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPorts.h"

#import "WMPatchCategories.h"
#import "WMPatchEventSource.h"

@class WMEAGLContext;
@class WMPort;
@class WMNumberPort;
@class WMBundleDocument;

@interface WMPatch : NSObject

+ (NSArray *)patchClasses;

//Will pick the correct patch class to represent this object
+ (id)patchWithPlistRepresentation:(id)inPlist;

+ (id)defaultValueForInputPortKey:(NSString *)inKey;

//Override to do your own setup
- (id)initWithPlistRepresentation:(id)inPlist;
- (id)plistRepresentation;

//Call in +load for any WMPatch subclass
+ (void)registerPatchClass;

+ (NSString *)humanReadableTitle;

- (BOOL)setPlistState:(id)inPlist;
- (id)plistState;

@property (nonatomic, readonly) NSArray *inputPorts;
@property (nonatomic, readonly) NSArray *outputPorts;

@property (nonatomic, readonly) NSArray *systemInputPorts;
@property (nonatomic, readonly) NSArray *systemOutputPorts;

@property (nonatomic) BOOL hasSetup;

- (void)addInputPort:(WMPort *)inPort;
- (void)addOutputPort:(WMPort *)inPort;

- (void)removeInputPort:(WMPort *)inPort;
- (void)removeOutputPort:(WMPort *)inPort;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSArray *connections;

//For now just find in children (not sub-children)
- (WMPatch *)patchWithKey:(NSString *)inKey;

- (WMPort *)inputPortWithKey:(NSString *)inKey;
- (WMPort *)outputPortWithKey:(NSString *)inKey;

//Render
- (BOOL)setup:(WMEAGLContext *)context;
- (void)enable:(WMEAGLContext *)context;
- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary*)args;
- (void)disable:(WMEAGLContext *)context;
- (void)cleanup:(WMEAGLContext *)context;

//Editor

+ (NSString *)category;
@property (nonatomic, readonly) UIColor *editorColor;

@property (nonatomic) CGPoint editorPosition;
- (void)addChild:(WMPatch *)inPatch;
- (void)removeChild:(WMPatch *)inPatch;
- (void)addConnectionFromPort:(NSString *)inPort ofPatch:(NSString *)fromPatch toPort:(NSString *)toPort ofPatch:(NSString *)toPatch;
- (void)removeConnectionToPort:(NSString *)inPort ofPatch:(NSString *)toPatch;

@end


