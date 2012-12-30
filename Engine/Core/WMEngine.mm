//
//  WMEngine.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMEngine.h"

#import "GLKMatrix4_cpp.h"

#import "WMPatch.h"
#import "WMConnection.h"
#import "WMPort.h"

#import "WMPatch+GraphAlgorithms.h"

#import "WMEAGLContext.h"
#import "WMFramebuffer.h"
#import "wMCompositionSerialization.h"
#import "WMComposition.h"
#import "WMFrameCounter.h"

#import <QuartzCore/QuartzCore.h>

#define DEBUG_LOG_RENDER_MATRICES 0

NSString *const WMEngineArgumentsInterfaceOrientationKey = @"interfaceOrientation";
NSString *const WMEngineArgumentsCompositionKey = @"composition";
NSString *const WMEngineArgumentsOutputDimensionsKey = @"outputDimensions";

@interface WMEngine ()
@property (nonatomic, strong, readwrite) WMPatch *rootObject;

@end


@implementation WMEngine {
	NSMutableDictionary *compositionUserData;
	WMFrameCounter *_frameCounter;
	NSCache *_orderingCache;
	NSCache *_connectionCache;
}

@synthesize renderContext;
@synthesize rootObject;
@synthesize document;
@synthesize t;
@synthesize previousAbsoluteTime;
@synthesize frameNumber;
@synthesize eventSource = _eventSource;
@synthesize frame = _frame;
@synthesize interfaceOrientation = _interfaceOrientation;
@synthesize renderFramebuffer = _renderFramebuffer;
@synthesize delegate;

- (id)initWithRootPatch:(WMPatch *)inPatch;
{
	self = [super init];
	if (self == nil) return self; 

#if TARGET_OS_IPHONE
	renderContext = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
#endif
	_frameCounter = [[WMFrameCounter alloc] init];
	self.rootObject = inPatch;
	compositionUserData = [[NSMutableDictionary alloc] init];

	_orderingCache = [[NSCache alloc] init];
	_connectionCache = [[NSCache alloc] init];
	
	return self;
}

- (id)initWithBundle:(WMComposition *)inDocument;
{
	if (!inDocument) {
		return nil;
	}
	
	self = [self initWithRootPatch:inDocument.rootPatch];
	if (self == nil) return self; 
	
	self.document = inDocument;
	if (document.userDictionary)
		[compositionUserData addEntriesFromDictionary:document.userDictionary];
	
	return self;
}

//TODO: This could be done with an "enumerate children recursive with block"
- (void)_cleanupRecursive:(WMPatch *)inPatch;
{
	[inPatch cleanup:renderContext];
	for (WMPatch *patch in inPatch.children) {
		[self _cleanupRecursive:patch];
	}	
}

- (void)dealloc
{
	//TODO: expose the idea of cleanup outside of -dealloc
	//Call cleanup on all patches
	[WMEAGLContext setCurrentContext:renderContext];
	[self _cleanupRecursive:rootObject];
}

- (void)_setupRecursive:(WMPatch *)inPatch;
{
	if (!inPatch.hasSetup) {
		[inPatch setup:renderContext];
		inPatch.hasSetup = YES;
		
	}
	for (WMPatch *patch in inPatch.children) {
		//This could be done with an "enumerate children recursive with block"
		[self _setupRecursive:patch];
	}
}

- (WMPatch<WMPatchEventSource> *)_findEventSource:(WMPatch *)patch;
{
	WMPatch<WMPatchEventSource> *eventSource;
	for (WMPatch *p in patch.children) {
		if ([p conformsToProtocol:@protocol(WMPatchEventSource)]) {
			ZAssert(!eventSource, @"More than one event source found!");
			eventSource = (WMPatch<WMPatchEventSource> *)p;
		}
	}
	return eventSource;
}

- (void)setEventSource:(WMPatch<WMPatchEventSource> *)eventSource;
{
	_eventSource = eventSource;
	_eventSource.eventDelegate = self;
}

- (void)start;
{
	[WMEAGLContext setCurrentContext:self.renderContext];
	//Call setup on all patches
	[self _setupRecursive:rootObject];
	
	//Find the event source
	self.eventSource = [self _findEventSource:rootObject];
	self.eventSource.eventDelegatePaused = NO;

	frameNumber = 0;
	previousAbsoluteTime = CFAbsoluteTimeGetCurrent();

}

- (void)stop;
{
	self.eventSource.eventDelegatePaused = YES;
}

- (void)beginConfiguration;
{
	
}

- (void)commitConfiguration;
{
	//Find the event source
	self.eventSource = [self _findEventSource:rootObject];
	[_orderingCache removeAllObjects];
	[_connectionCache removeAllObjects];
}

//TODO: use this method to reduce the number of nodes executed
- (void)addAllNeedsUpdate:(NSMutableSet *)inNeedsUpdate;
{
	//Find everything that changes every frame
	
	//Iteratively add all objects connected to the inNeedsUpdate set
	//Stop when no new objects have been added
	
	//TODO: this could be made more efficent I think
}


//This only supports children of a node NOT sub-children for now!!
//Perhaps use an iterator aka NSEnumerator?
- (NSArray *)executionOrderingOfChildren:(WMPatch *)inPatch;
{
	NSArray *executionOrdering = nil;
	NSSet *excludedEdges = nil;
	
	NSValue *cacheKey = [NSValue valueWithPointer:(const void *)inPatch];
	executionOrdering = [_orderingCache objectForKey:cacheKey];
	if (executionOrdering) {
		return executionOrdering;
	} else if ([inPatch getTopologicalOrdering:&executionOrdering andExcludedEdges:&excludedEdges]) {
		[_orderingCache setObject:executionOrdering forKey:cacheKey];
		return executionOrdering;
	} else {
		return nil;
	}
}

#pragma -

- (WMConnection *)connectionToInputPort:(WMPort *)inPort ofNode:(WMPatch *)inPatch inParent:(WMPatch *)inParent;
{
	NSValue *cacheKey = [NSValue valueWithPointer:(const void *)inPort];
	
	WMConnection *connection = [_connectionCache objectForKey:cacheKey];
	if (connection) {
		return connection;
	} else {
		for (WMConnection *connection in inParent.connections) {
			if ([connection.destinationNode isEqualToString:inPatch.key] && [connection.destinationPort isEqualToString:inPort.key]) {
				[_connectionCache setObject:connection forKey:cacheKey];
				return connection;
			}
		}
	}
	return nil;
}

- (void)patchGeneratedUpdateEvent:(id <WMPatchEventSource>)patch atTime:(double)time;
{
#if TARGET_OS_IPHONE
	BOOL applicationCanUseOpenGL = [UIApplication sharedApplication].applicationState != UIApplicationStateBackground;
	if (!applicationCanUseOpenGL) {
		NSLog(@"Trying to update when GL not allowed: %lf", time);
		return;
	}
#endif
	
	BOOL ok = [self.delegate engineShouldRenderFrame:self];
	
	if (ok) {
		NSTimeInterval frameStartTime = CACurrentMediaTime();
		
		[self drawFrame];
		[self.renderFramebuffer presentRenderbuffer];
		
		NSTimeInterval frameEndTime = CACurrentMediaTime();
		
		NSTimeInterval timeToDrawFrame = frameEndTime - frameStartTime;
		[_frameCounter recordFrameWithTime:frameEndTime duration:timeToDrawFrame];
		
		[self.delegate engineDidRenderFrame:self];
	}
}

- (void)drawPatchRecursive:(WMPatch *)inPatch;
{
	/// Write values of input ports to inPatch's children ///
	//TODO: rename ivarInputPorts!
	for (WMPort *port in [inPatch inputPorts]) {
		if (port.originalPort) {
			[port.originalPort takeValueFromPort:port];
		}
	}
	
	NSMutableSet *transientPorts = [NSMutableSet set];
	
	//// Render order ////
	NSArray *ordering = [self executionOrderingOfChildren:inPatch];
	
	//// Render       ////
	BOOL success = YES;
	for (WMPatch *patch in ordering) {
		//Write the values of the input ports from the output ports of the connections
		for (WMPort *inputPort in [patch inputPorts]) {
			//TODO: keep a record of what connections are connected to what ports for efficency here
			//Find a connection to this input port
			WMConnection *connection = [self connectionToInputPort:inputPort ofNode:patch inParent:inPatch];
			if (!connection) {
				inputPort.connectedPort = nil;
				if (inputPort.isInputValueTransient) {
					[transientPorts addObject:inputPort];
				}
				continue;
			}
			WMPatch *sourcePatch = [inPatch patchWithKey:connection.sourceNode];
			WMPort *sourcePort = [sourcePatch outputPortWithKey:connection.sourcePort];
			inputPort.connectedPort = sourcePort;
			[inputPort takeValueFromPort:sourcePort];
			//NSLog(@"connection %@ passing value %@", connection, sourcePort.objectValue);
		}

		//NSLog(@"executing patch: %@", patch.key);
		success = [patch execute:renderContext time:t arguments:compositionUserData];
		if (!success) {
			NSLog(@"Error executing patch: %@", patch);
			break;
		}
		GL_CHECK_ERROR;
		
		//Now execute any children
		if ([patch children].count > 0) {
			[self drawPatchRecursive:patch];
		}		
	}
	
	/// Write values of output ports from inPatch's children ///
	for (WMPort *port in [inPatch outputPorts]) {
		if (port.originalPort) {
			[port takeValueFromPort:port.originalPort];
		}
	}
	
	//Clear transient input ports
	for (WMPort *inputPort in transientPorts) {
		inputPort.objectValue = nil;
	}
}

- (void)drawFrame;
{
	ZAssert(self.renderFramebuffer, @"Must have a framebuffer to render to");
	[WMEAGLContext setCurrentContext:renderContext];
	[renderContext renderToFramebuffer:self.renderFramebuffer block:^{
		
		ZAssert(!CGRectIsEmpty(self.frame), @"Must specify a rect to render");
		
		[self drawFrameInRect:self.frame interfaceOrientation:self.interfaceOrientation];
		
	}];
}

- (void)drawFrameInRect:(CGRect)inBounds interfaceOrientation:(UIInterfaceOrientation)inInterfaceOrientation;
{
	//Pass along the device orientation. This is necessary for patches whose semantics are dependent on which direction is "up" for the user.
	//Examples: accelerometer, camera input.
	[compositionUserData setObject:[NSNumber numberWithInteger:inInterfaceOrientation] forKey:WMEngineArgumentsInterfaceOrientationKey];
	if (document) {
		[compositionUserData setObject:document forKey:WMEngineArgumentsCompositionKey];
	}
	
	[compositionUserData setObject:[NSValue valueWithCGSize:inBounds.size] forKey:WMEngineArgumentsOutputDimensionsKey];
	
	//Make sure we have set up all new node
	[self _setupRecursive:self.rootObject];
	
	//Clear out the rendering context
	[renderContext clearToColor:(GLKVector4){0, 0, 0, 1}];
	[renderContext clearDepth];
	
	//// Time         ////
	//TODO: support pause / resume
	CFAbsoluteTime currentAbsoluteTime = CFAbsoluteTimeGetCurrent();
	t += currentAbsoluteTime - previousAbsoluteTime;
	previousAbsoluteTime = currentAbsoluteTime;
	
	[self drawPatchRecursive:self.rootObject];
	frameNumber++;
}


- (double)frameRate;
{
	return _frameCounter.fps;
}

- (double)frameDuration;
{
	return _frameCounter.lastDuration;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p frame:%d t:%.3lf t-1:%.3lf>", [self class], self, (int)frameNumber, t, previousAbsoluteTime];
}

@end
