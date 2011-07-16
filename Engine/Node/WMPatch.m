//
//  WMPatch.m
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

#import "WMConnection.h"
#import "WMEAGLContext.h"

#import "WMPort.h"

#import <objc/objc.h>
#import <objc/runtime.h>

NSString *WMCompositionPathKey = @"WMCompositionPathKey";

NSString *WMPatchClassPlistName = @"class";
NSString *WMPatchPluginClassPlistName = @"identifier";
NSString *WMPatchKeyPlistName = @"key";
NSString *WMPatchStatePlistName = @"state";
NSString *WMPatchConnectionsPlistName = @"connections";
NSString *WMPatchChildrenPlistName = @"nodes";

@interface WMPlaceholderPatch : WMPatch {
@private
    NSString *originalClassName;
}
@end


@interface WMPatch ()


@end

@implementation WMPatch
@synthesize connections;
@synthesize children;
@synthesize key;
@synthesize editorPosition;

+ (NSMutableDictionary *)_classMap;
{
	static NSMutableDictionary *classMap;
	@synchronized(@"WMPatchClassMap") {
		if (!classMap) {
			classMap = [[NSMutableDictionary alloc] init];
		}
	}
	return classMap;
}

+ (NSMutableDictionary *)_pluginClassMap;
{
	static NSMutableDictionary *classMap;
	@synchronized(@"WMPatchPluginClassMap") {
		if (!classMap) {
			classMap = [[NSMutableDictionary alloc] init];
		}
	}
	return classMap;
}


+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCPatch"]];
	[pool drain];
}

+ (void)registerToRepresentClassNames:(NSSet *)inClassNames;
{
	NSAssert([NSThread currentThread] == [NSThread mainThread], @"registerToRepresentClassNames: must be called on the main thread!");
	NSMutableDictionary *classMap = [self _classMap];
	for (NSString *className in inClassNames) {
		[classMap setObject:self forKey:className];
	}
}

+ (void)registerToRepresentPluginClassNames:(NSSet *)inClassNames;
{
	NSAssert([NSThread currentThread] == [NSThread mainThread], @"registerToRepresentPluginClassNames: must be called on the main thread!");
	NSMutableDictionary *classMap = [self _pluginClassMap];
	for (NSString *className in inClassNames) {
		[classMap setObject:self forKey:className];
	}
}

+ (id)patchWithPlistRepresentation:(id)inPlist;
{
	NSString *patchClassName = [inPlist objectForKey:WMPatchClassPlistName];
	if (!patchClassName) {
		//Default to making a WMPatch
		//TODO: default instead to a placeholder / error node type?
		patchClassName = NSStringFromClass([WMPatch class]);
	}
	
	Class patchClass = nil;
	if ([patchClassName isEqualToString:@"QCPlugInPatch"]) {
		NSString *pluginClassName = [inPlist objectForKey:WMPatchPluginClassPlistName];
		//Plugins we have to load differently
		patchClass = [[self _pluginClassMap] objectForKey: pluginClassName];
		if (!patchClass) {
			patchClass = NSClassFromString(pluginClassName);
		}
	} else {
		patchClass = [[self _classMap] objectForKey: patchClassName];
		if (!patchClass) {
			patchClass = NSClassFromString(patchClassName);
		}		
	}
	
	if (!patchClass) {
		patchClass = [WMPlaceholderPatch class];
	}
	
	return [[patchClass alloc] initWithPlistRepresentation:inPlist];
}

- (WMPort *)portForIvar:(Ivar)inIvar key:(NSString *)inKey;
{
	const char* type = ivar_getTypeEncoding(inIvar);
	const int len = strlen(type);
	
	char *classNameStr = malloc(len + 1);
	//Parse the type string into the className
	size_t classNameStrLen = 0;
	if (type[0] == '{') { // {UIImage=#@@@} style
		//TODO: is this code path actually used??
		//Grr.
		int i = 1;
		while (i < len && type[i] != '=') {
			classNameStr[classNameStrLen++] = type[i++];
		}
	} else if (type[0] == '@' && len > 1 && type[1] == '"') { // @"UIImage" style
		int i = 2;
		while (i < len && type[i] != '"') {
			classNameStr[classNameStrLen++] = type[i++];
		}
	}
	NSString *className = [[NSString alloc] initWithBytes:classNameStr length:classNameStrLen encoding:NSUTF8StringEncoding];
	free(classNameStr);
	
	Class portClass = NSClassFromString(className);
	[className release];
	
	WMPort *port = [[[portClass alloc] init] autorelease];
	port.key = inKey;
	
	return port;
}

- (void)createIvarPorts;
{
	unsigned int count = 0;

	for (Class class = [self class]; class; class = [class superclass]) {
		Ivar *ivars = class_copyIvarList(class, &count);
		for (int i=0; i<count; i++) {
			NSString *ivarName = [[[NSString alloc] initWithCString:ivar_getName(ivars[i]) encoding:NSUTF8StringEncoding] autorelease];
			if (([ivarName hasPrefix:@"input"] || [ivarName hasPrefix:@"_input"]) && ![ivarName isEqualToString:@"inputPorts"]) {
				
				if ([ivarName isEqualToString:@"_inputEnable"]) {
					ivarName = @"_enable";
				} else if ([ivarName hasPrefix:@"_"]) {
					ivarName = [ivarName substringFromIndex:1];
				}
				NSLog(@"Create ivar input: %@", ivarName);
				WMPort *inputPort = [self portForIvar:ivars[i] key:ivarName];
				if (inputPort) {
					object_setIvar(self, ivars[i], inputPort);
					[inputPort retain];
					[self addInputPort:inputPort];
				}
				
			} else if (([ivarName hasPrefix:@"output"] || [ivarName hasPrefix:@"_output"]) && ![ivarName isEqualToString:@"outputPorts"]) {
				
				if ([ivarName hasPrefix:@"_"]) {
					ivarName = [ivarName substringFromIndex:1];
				}
				//			NSLog(@"Create ivar output: %@", ivarName);
				WMPort *outputPort = [self portForIvar:ivars[i] key:ivarName];
				if (outputPort) {
					object_setIvar(self, ivars[i], outputPort);
					[outputPort retain];
					[self addOutputPort:outputPort];
				}
				
			}
		}
		free(ivars);
	}
	
}

- (WMPatchExecutionMode)executionMode;
{
	return kWMPatchExecutionModeProcessor;
}

- (void)createChildrenWithState:(NSDictionary *)state;
{
	NSArray *plistChildren = [state objectForKey:WMPatchChildrenPlistName];
	for (NSDictionary *childDictionary in plistChildren) {
		WMPatch *child = [WMPatch patchWithPlistRepresentation:childDictionary];
		if (child) {
			[self addChild:child];
		}
	}
}

- (void)createConnectionsWithState:(NSDictionary *)state;
{
	NSDictionary *plistConnections = [state objectForKey:WMPatchConnectionsPlistName];
	for (NSString *connectionName in plistConnections) {
		NSDictionary *connectionDictionary = [plistConnections objectForKey:connectionName];
		WMConnection *connection = [[WMConnection alloc] init];
		connection.name = connectionName;
		connection.sourceNode = [connectionDictionary objectForKey:@"sourceNode"];
		connection.sourcePort = [connectionDictionary objectForKey:@"sourcePort"];
		connection.destinationNode = [connectionDictionary objectForKey:@"destinationNode"];
		connection.destinationPort = [connectionDictionary objectForKey:@"destinationPort"];
		[connections addObject: connection];
		[connection release];
	}
}


- (void)createPublishedInputPortsWithState:(NSDictionary *)state;
{
	NSArray *ports = [state objectForKey:@"publishedInputPorts"];
	for (NSDictionary *portDefinition in ports) {
		NSString *portKey = [portDefinition objectForKey:@"key"];
		WMPatch *child = [self patchWithKey:[portDefinition objectForKey:@"node"]];
		//Find the port on the child and use the same port class
		
		WMPort *childPort = [child inputPortWithKey:[portDefinition objectForKey:@"port"]];
		if (childPort) {
			Class portClass = [childPort class];
			WMPort *port = [[[portClass alloc] init] autorelease];
			port.key = portKey;
			port.originalPort = childPort;
			[self addInputPort:port];
			[port setStateValue:[[portDefinition objectForKey:@"state"] objectForKey:@"value"]];
		}
		
	}
}

- (void)createPublishedOutputPortsWithState:(NSDictionary *)state;
{
	NSArray *ports = [state objectForKey:@"publishedOutputPorts"];
	for (NSDictionary *portDefinition in ports) {
		NSString *portKey = [portDefinition objectForKey:@"key"];
		WMPatch *child = [self patchWithKey:[portDefinition objectForKey:@"node"]];
		//Find the port on the child and use the same port class
		
		WMPort *childPort = [child outputPortWithKey:[portDefinition objectForKey:@"port"]];
		if (childPort) {
			Class portClass = [childPort class];
			WMPort *port = [[portClass alloc] init];
			port.key = portKey;
			port.originalPort = childPort;
			[self addOutputPort:port];
			[port setStateValue:[[portDefinition objectForKey:@"state"] objectForKey:@"value"]];
		}
		
	}
	
}


- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super init];
	if (!self) return nil;
		
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	children = [[NSMutableArray alloc] init];
	childrenByKey = [[NSMutableDictionary alloc] init];
	connections = [[NSMutableArray alloc] init];
	
	self.key = [inPlist objectForKey:WMPatchKeyPlistName];
	
	outputPorts = [[NSMutableArray alloc] init];
	inputPorts = [[NSMutableArray alloc] init];
	
	//Create ivar ports for this 
	[self createIvarPorts];
	
	NSDictionary *state = [inPlist objectForKey:WMPatchStatePlistName];
		
	//Set state of ivar ports
	[self setPlistState:state];
	
	//Create children
	[self createChildrenWithState:state];
			
	//Create connections among children
	[self createConnectionsWithState:state];
	
	//Create published input and output ports (use the type of child's port to make our port type)
	[self createPublishedInputPortsWithState:state];
	[self createPublishedOutputPortsWithState:state];
		
	[pool drain];
	
	return self;
}

- (void)dealloc {
	[userInfo release];
    [children release];
	[childrenByKey release];
	[connections release];
    [super dealloc];
}

- (BOOL)setPlistState:(id)inPlist;
{
	//set values of input ports!

	//Combine "customInputPortStates" and "ivarInputPortStates"
	NSDictionary *ivarInputPortStates = [inPlist objectForKey:@"ivarInputPortStates"];
	ZAssert(!ivarInputPortStates || [ivarInputPortStates isKindOfClass:[NSDictionary class]], @"ivarInputPortStates must be a dictionary!");
	NSDictionary *customInputPortStates = [inPlist objectForKey:@"customInputPortStates"];
	ZAssert(!customInputPortStates || [customInputPortStates isKindOfClass:[NSDictionary class]], @"customInputPortStates must be a dictionary!");
	NSMutableDictionary *inputPortStates = [NSMutableDictionary dictionary];
	if (ivarInputPortStates) {
		[inputPortStates addEntriesFromDictionary:ivarInputPortStates];
	}
	if (customInputPortStates) {
		[inputPortStates addEntriesFromDictionary:customInputPortStates];
	}
	for (WMPort *inputPort in [self inputPorts]) {
		NSDictionary *state = [inputPortStates objectForKey:inputPort.key];
		id value = [state objectForKey:@"value"];
		if (value) {
			BOOL ok = [inputPort setStateValue:value];
			if (!ok) {
				NSLog(@"Couldn't set state %@ on input port %@ of patch %@", state, inputPort.name, self.key);
			}
		}
	}
	
	return YES;
}

- (id)plistState;
{
	return nil;
}

- (void)addInputPort:(WMPort *)inPort;
{
	[self willChangeValueForKey:@"inputPorts"];
	[inputPorts addObject:inPort];
	[self didChangeValueForKey:@"inputPorts"];
}

- (void)addOutputPort:(WMPort *)inPort;
{
	[self willChangeValueForKey:@"outputPorts"];
	[outputPorts addObject:inPort];	
	[self didChangeValueForKey:@"outputPorts"];
}

- (NSArray *)inputPorts;
{
	return [[inputPorts retain] autorelease];
}
- (NSArray *)outputPorts;
{
	return [[outputPorts retain] autorelease];
}

- (NSArray *)systemInputPorts;
{
	return [NSArray arrayWithObjects:/*system_inputTime,*/ nil];
}

- (NSArray *)systemOutputPorts;
{
	return nil;
}


- (WMPatch *)patchWithKey:(NSString *)inKey;
{
	return [childrenByKey objectForKey:inKey];
}

- (WMPort *)inputPortWithKey:(NSString *)inName;
{
	for (WMPort *port in [self inputPorts]) {
		if ([port.key isEqualToString:inName]) {
			return port;
		}
	}
	return nil;
}

- (WMPort *)outputPortWithKey:(NSString *)inName;
{
	for (WMPort *port in [self outputPorts]) {
		if ([port.key isEqualToString:inName]) {
			return port;
		}
	}
	return nil;
}


#pragma mark -
#pragma mark Execution
- (BOOL)setup:(WMEAGLContext *)context;
{
	//Override me
	return YES;
}

- (void)enable:(WMEAGLContext*)context;
{
	//Override me
	return;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	//Override me
	return YES;
}

- (void)disable:(WMEAGLContext*)context;
{
	//Override me
	return;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	//Override me
	return;
}

#pragma mark -

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{key: %@, connections: %u, childen: %u>}", NSStringFromClass([self class]), self, key, connections.count, children.count];
}

- (NSString *)descriptionRecursive;
{
	NSMutableString *descriptionRecursive = [NSMutableString stringWithString:[self description]];
	for (WMPatch *child in children) {
		[descriptionRecursive appendFormat:@"\n\t%@", [child descriptionRecursive]];
	}
	[descriptionRecursive appendString:@"\n"];
	return descriptionRecursive;
}


- (void)addChild:(WMPatch *)inPatch;
{
	[children addObject:inPatch];
	[childrenByKey setObject:inPatch forKey:inPatch.key];
}

- (void)addConnectionFromPort:(NSString *)fromPort ofPatch:(NSString *)fromPatch toPort:(NSString *)toPort ofPatch:(NSString *)toPatch;
{
	NSMutableArray *connectionsMutable = [NSMutableArray arrayWithArray:connections];
	
	WMConnection *connection = [[WMConnection alloc] init];
	connection.sourceNode = fromPatch;
	connection.sourcePort = fromPort;
	connection.destinationNode = toPatch;
	connection.destinationPort = toPort;

	[connectionsMutable addObject:connection];
	
	[connections release];
	connections = [connectionsMutable copy];
}

@end

@implementation WMPlaceholderPatch

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	originalClassName = [[inPlist objectForKey:WMPatchClassPlistName] retain];
	
	return self;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ (was %@) : %p>{key: %@, connections: %u, childen: %u>}", NSStringFromClass([self class]), originalClassName, self, key, connections.count, children.count];
}

@end