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
#import "WMPatchCategories.h"

#import "WMEngine.h"
#import "WMPort.h"

#import <objc/objc.h>
#import <objc/runtime.h>

NSString *WMPatchClassPlistName = @"class";
NSString *WMPatchKeyPlistName = @"key";
NSString *WMPatchStatePlistName = @"state";
NSString *WMPatchConnectionsPlistName = @"connections";
NSString *WMPatchChildrenPlistName = @"nodes";

NSString *WMPatchEditorPositionPlistName = @"editorPosition";


@interface WMPlaceholderPatch : WMPatch {
@private
    NSString *originalClassName;
}
@end


@interface NSString(uncamelcase)
- (NSString *)uncamelcase;
@end

@implementation NSString(uncamelcase)

- (NSString *)uncamelcase {
    NSMutableString *s = [NSMutableString string];
    NSCharacterSet *set = [NSCharacterSet uppercaseLetterCharacterSet];
    for (unsigned i = 0; i < self.length; i++) {
        unichar c = [self characterAtIndex:i];
        if ([set characterIsMember:c]) {
            if (i > 0) [s appendString:@" "];
        }
        [s appendFormat:@"%C",c];
    }
    return s;
}

@end

@interface WMPatch ()
- (void)_initializeStateForInputPort:(WMPort *)inPort;
@end

@implementation WMPatch  {
@protected;
	//These don't have input at the beginning
	WMNumberPort *system_inputTime;
	//TODO: QCBooleanPort system_inputEnable;
	
	//Keep around a dictionary of formerly-used input values in order to correctly restore state for dynamic ports that don't exist before -setup
	NSDictionary *storedInputPortValues;
	
    NSMutableArray *_connections;
	NSMutableArray *_children;
	NSMutableDictionary *childrenByKey;
	id userInfo;
	
	//These are set from the ivars
	NSMutableArray *inputPorts;
	NSMutableArray *outputPorts;
	
	//Render
	CFAbsoluteTime lastExecutionTime;
}

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

+ (NSString *)category;
{
    NSLog(@"Need to override category in %@.", self);
    return WMPatchCategoryUnknown;
}

+ (NSArray *)patchClasses;
{
	NSMutableArray *outPatchClasses = [NSMutableArray array];
	[[self _classMap] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[outPatchClasses addObject:NSStringFromClass(obj)];
	}];
	return outPatchClasses;
}


+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (void)registerPatchClass;
{
	NSAssert([NSThread currentThread] == [NSThread mainThread], @"registerToRepresentClassNames: must be called on the main thread!");
	NSMutableDictionary *classMap = [self _classMap];

	[classMap setObject:self forKey:NSStringFromClass(self)];

	[[WMPatchCategories sharedInstance] addClassWithName:self key:NSStringFromClass(self)];
}

+ (id)patchWithPlistRepresentation:(id)inPlist;
{
	NSString *patchClassName = [inPlist objectForKey:WMPatchClassPlistName];
	if (!patchClassName) {
		//Default to making a WMPatch
		//TODO: default instead to a placeholder / error node type?
		patchClassName = NSStringFromClass([WMPatch class]);
	}
	
	Class patchClass = [[self _classMap] objectForKey: patchClassName];
	if (!patchClass) {
		patchClass = NSClassFromString(patchClassName);
	}
	
	if (!patchClass) {
		patchClass = [WMPlaceholderPatch class];
	}
	
	return [[patchClass alloc] initWithPlistRepresentation:inPlist];
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	return nil;
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
	
	WMPort *port = [[portClass alloc] init];
	port.key = inKey;
	
	return port;
}

- (void)createIvarPorts;
{
	unsigned int count = 0;

	for (Class class = [self class]; class; class = [class superclass]) {
		Ivar *ivars = class_copyIvarList(class, &count);
		for (int i=0; i<count; i++) {
			NSString *ivarName = [[NSString alloc] initWithCString:ivar_getName(ivars[i]) encoding:NSUTF8StringEncoding];
			if (([ivarName hasPrefix:@"input"] || [ivarName hasPrefix:@"_input"]) && ![ivarName isEqualToString:@"inputPorts"]) {
				
				if ([ivarName isEqualToString:@"_inputEnable"]) {
					ivarName = @"_enable";
				} else if ([ivarName hasPrefix:@"_"]) {
					ivarName = [ivarName substringFromIndex:1];
				}
				WMPort *inputPort = [self portForIvar:ivars[i] key:ivarName];
				if (inputPort) {
					object_setIvar(self, ivars[i], inputPort);
					[self addInputPort:inputPort];
				}
				
			} else if (([ivarName hasPrefix:@"output"] || [ivarName hasPrefix:@"_output"]) && ![ivarName isEqualToString:@"outputPorts"]) {
				
				if ([ivarName hasPrefix:@"_"]) {
					ivarName = [ivarName substringFromIndex:1];
				}
				WMPort *outputPort = [self portForIvar:ivars[i] key:ivarName];
				if (outputPort) {
					object_setIvar(self, ivars[i], outputPort);
					[self addOutputPort:outputPort];
				}
				
			}
		}
		free(ivars);
	}
	
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
		[_connections addObject: connection];
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
			WMPort *port = [[portClass alloc] init];
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
		
	@autoreleasepool {
	
		_children = [[NSMutableArray alloc] init];
		childrenByKey = [[NSMutableDictionary alloc] init];
		_connections = [[NSMutableArray alloc] init];
		
		self.key = [inPlist objectForKey:WMPatchKeyPlistName];
		
		outputPorts = [[NSMutableArray alloc] init];
		inputPorts = [[NSMutableArray alloc] init];
		
		//Create ivar ports for this 
		[self createIvarPorts];
		
		NSDictionary *state = [inPlist objectForKey:WMPatchStatePlistName];
			
		//Set state of ivar ports
		[self setPlistState:state];
		for (WMPort *port in inputPorts) {
			[self _initializeStateForInputPort:port];
		}
				
		//Set position
		NSString *posStr = [inPlist objectForKey:WMPatchEditorPositionPlistName];
		if (posStr) {
			self.editorPosition = CGPointFromString(posStr);
		}
		
		
		return self;
	}
}

//This will make sure values are preserved
- (void)_initializeStateForInputPort:(WMPort *)inPort;
{
	NSDictionary *state = [storedInputPortValues objectForKey:inPort.key];
	id value = [state objectForKey:@"value"];
	BOOL done = NO;
	//Set the state to the stored value
	if (value) {
		done = [inPort setStateValue:value];
	}
	//Set the state to the default value
	if (!done) {
		value = [[self class] defaultValueForInputPortKey:inPort.key];
		if (value) {
			done = [inPort setStateValue:value];
		}
	}
}

- (id)plistRepresentation;
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	//Serialize class
	[dict setObject:NSStringFromClass([self class]) forKey:WMPatchClassPlistName];
	
	//Serialize key
	[dict setObject:self.key forKey:WMPatchKeyPlistName];
	
	//Serialize plist state
	[dict setObject:self.plistState forKey:WMPatchStatePlistName];
		
	//Serialize position
	[dict setObject:NSStringFromCGPoint(self.editorPosition) forKey:WMPatchEditorPositionPlistName];
	
	return dict;
}


- (BOOL)setPlistState:(id)inPlist;
{
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
	storedInputPortValues = inputPortStates;

	//Create children
	[self createChildrenWithState:inPlist];
	
	//Create connections among children
	[self createConnectionsWithState:inPlist];
	
	//Create published input and output ports (use the type of child's port to make our port type)
	[self createPublishedInputPortsWithState:inPlist];
	[self createPublishedOutputPortsWithState:inPlist];

	return YES;
}

- (id)plistState;
{
	
	NSMutableDictionary *plistState = [NSMutableDictionary dictionary];
	//TODO: serialize custom input ports
	
	NSMutableDictionary *inputPortStates = [NSMutableDictionary dictionary];
	//Save values of input ports
	for (WMPort *inputPort in [self inputPorts]) {
		id stateValue = [inputPort stateValue];
		if (stateValue) {
			if ([NSPropertyListSerialization propertyList:stateValue isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
				NSDictionary *valueDict = [NSDictionary dictionaryWithObject:[inputPort stateValue] forKey:@"value"];
				
				[inputPortStates setObject:valueDict forKey:inputPort.key];
			} else {
				NSLog(@"%@ returned invalid stateValue(%@ %@) for inputPort %@", self, [stateValue class], stateValue, inputPort);
			}
		}
	}
	[plistState setObject:inputPortStates forKey:@"ivarInputPortStates"];
	
	//Serialize connections
	NSMutableDictionary *cpl = [NSMutableDictionary dictionary];
	int cnum = 1;
	for (WMConnection *c in self.connections) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:c.sourceNode forKey:@"sourceNode"];
		[d setObject:c.sourcePort forKey:@"sourcePort"];
		[d setObject:c.destinationNode forKey:@"destinationNode"];
		[d setObject:c.destinationPort forKey:@"destinationPort"];
		
		[cpl setObject:d forKey:[NSString stringWithFormat:@"connection-%d", cnum]];
		cnum++;
	}
	[plistState setObject:cpl forKey:WMPatchConnectionsPlistName];
	
	//Serialize children
	NSMutableArray *childrenRep = [NSMutableArray array];
	for (WMPatch *p in self.children) {
		[childrenRep addObject:[p plistRepresentation]];
	}
	[plistState setObject:childrenRep forKey:WMPatchChildrenPlistName];

	return plistState;
}

- (void)addInputPort:(WMPort *)inPort;
{
	[self willChangeValueForKey:@"inputPorts"];
	[inputPorts addObject:inPort];
	[self didChangeValueForKey:@"inputPorts"];
	
	[self _initializeStateForInputPort:inPort];
}

- (void)addOutputPort:(WMPort *)inPort;
{
	[self willChangeValueForKey:@"outputPorts"];
	[outputPorts addObject:inPort];	
	[self didChangeValueForKey:@"outputPorts"];
}

- (void)removeInputPort:(WMPort *)inPort;
{
	[self willChangeValueForKey:@"inputPorts"];
	[inputPorts removeObject:inPort];
	[self didChangeValueForKey:@"inputPorts"];
}

- (void)removeOutputPort:(WMPort *)inPort;
{
	[self willChangeValueForKey:@"outputPorts"];
	[outputPorts removeObject:inPort];
	[self didChangeValueForKey:@"outputPorts"];
}

- (NSArray *)inputPorts;
{
	return [inputPorts copy];
}
- (NSArray *)outputPorts;
{
	return [outputPorts copy];
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

- (NSArray *)children;
{
	return [_children copy];
}

- (NSArray *)connections;
{
	return [_connections copy];
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
	NSMutableArray *components = [NSMutableArray array];
	[components addObject:[NSString stringWithFormat:@"key: %@", _key]];
	if (_connections.count > 0) [components addObject: [NSString stringWithFormat:@"connections: %u", _connections.count]];
	if (_children.count > 0) [components addObject:[NSString stringWithFormat:@"childen: %u", _children.count]];
	
	return [NSString stringWithFormat:@"<%@: %p hasSetup:%d>{%@}", NSStringFromClass([self class]), self, self.hasSetup, [components componentsJoinedByString:@", "]];
}




//Provided as a debugging aid
- (NSString *)recursiveDescription;
{
	__block NSMutableString *s = [[NSMutableString alloc] init];
	
	__block void (^recursion)(WMPatch *, NSString *, NSString *) = [^(WMPatch *n, NSString *indent, NSString *connectionInfo) {
		[s appendFormat:@"%@ - %@ %@\n", indent, n, connectionInfo];
		
		for (WMPatch *child in n.children) {
			int inCount = 0;
			int outCount = 0;
			for (WMConnection *c in n.connections) {
				if ([c.destinationNode isEqualToString:child.key]) {
					inCount++;
				}
				if ([c.sourceNode isEqualToString:child.key]) {
					outCount++;
				}
			}
			connectionInfo = [NSString stringWithFormat:@" <- %d in %d out", inCount, outCount];
			recursion(child, [indent stringByAppendingString:@"\t"], connectionInfo);
		}
	} copy];
	//TODO: report bug: if block is not copied, we have a crash!
	recursion(self, @"", @"");
	return s;
}

- (NSString *)availableKeyForSubPatch:(WMPatch *)inPatch;
{
	if (!inPatch.key || [childrenByKey objectForKey:inPatch.key]) {
		NSString *defaultKey = NSStringFromClass([inPatch class]);
		int i = 0;
		if ([childrenByKey objectForKey:defaultKey]) {
			NSString *tryKey = nil;
			do {
				tryKey = [defaultKey stringByAppendingFormat:@"-%d", i];
				i++;
			} while ([childrenByKey objectForKey:tryKey]);
			return tryKey;
		}
		return defaultKey;
	} else {
		return inPatch.key;
	}
}

- (void)addChild:(WMPatch *)inPatch;
{
	if (![_children containsObject:inPatch]) {
		//Generate a key if necessary
		inPatch.key = [self availableKeyForSubPatch:inPatch];
		[_children addObject:inPatch];
	} 
	if ([childrenByKey objectForKey:inPatch.key] != inPatch) {
		[childrenByKey setObject:inPatch forKey:inPatch.key];
	}
}

- (void)removeChild:(WMPatch *)inPatch;
{
	//Remove any connections related
	for (WMConnection *connection in self.connections) {
		if ([connection.destinationNode isEqualToString:inPatch.key] || [connection.sourceNode isEqualToString:inPatch.key]) {
			[_connections removeObject:connection];
		}
	}
	[_children removeObject:inPatch];
	[childrenByKey removeObjectForKey:inPatch.key];
}

- (void)addConnectionFromPort:(NSString *)fromPort ofPatch:(NSString *)fromPatch toPort:(NSString *)toPort ofPatch:(NSString *)toPatch;
{
	[self removeConnectionToPort:toPort ofPatch:toPatch];
	
	WMConnection *connection = [[WMConnection alloc] init];
	connection.sourceNode = fromPatch;
	connection.sourcePort = fromPort;
	connection.destinationNode = toPatch;
	connection.destinationPort = toPort;

	NSAssert(fromPort && fromPatch && toPort && toPatch, @"Must fully specify connection %@", connection);
	
	[_connections addObject:connection];	
}

- (void)removeConnectionToPort:(NSString *)toPort ofPatch:(NSString *)toPatch;
{
	//Find an existing connection
	WMConnection *existingConnectionToInputPort = nil;
	for (WMConnection *connection in self.connections) {
		if ([connection.destinationNode isEqualToString:toPatch] && [connection.destinationPort isEqualToString:toPort]) {
			existingConnectionToInputPort = connection;
		}
	}
	if (existingConnectionToInputPort) {
		[_connections removeObject:existingConnectionToInputPort];
	}
}

+ (NSString *)humanReadableTitle {
    NSString *s = [NSMutableString stringWithString:NSStringFromClass(self)];
    if ([s hasPrefix:@"WM"]) s = [s substringFromIndex:2];
    return [s uncamelcase];
}


- (UIColor *)editorColor;
{
	return [UIColor colorWithWhite:0.0f alpha:0.3f];
}

@end

@implementation WMPlaceholderPatch

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	originalClassName = [inPlist objectForKey:WMPatchClassPlistName];
	
	return self;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ (was %@) : %p>{key: %@, connections: %u, childen: %u>}", NSStringFromClass([self class]), originalClassName, self, self.key, _connections.count, _children.count];
}


@end