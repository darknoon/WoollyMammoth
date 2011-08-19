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
#import "WMBundleDocument.h"

#define DEBUG_LOG_RENDER_MATRICES 0

NSString *const WMEngineArgumentsInterfaceOrientationKey = @"interfaceOrientation";
NSString *const WMEngineArgumentsDocumentKey = @"document";

@interface WMEngine ()
@property (nonatomic, retain, readwrite) WMPatch *rootObject;

@end


@implementation WMEngine

@synthesize renderContext;
@synthesize rootObject;
@synthesize document;

- (id)initWithBundle:(WMBundleDocument *)inDocument;
{
	self = [super init];
	if (self == nil) return self; 
	
	if (!inDocument) {
		[self release];
		return nil;
	}
	
	renderContext = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	self.document = inDocument;
	self.rootObject = document.rootPatch;
	compositionUserData = document.userDictionary ? [document.userDictionary mutableCopy] : [[NSMutableDictionary alloc] init];
	
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
	[self _cleanupRecursive:rootObject];
	
	[rootObject release];
	[renderContext release];
	[compositionUserData release];
	[document release];

	[super dealloc];
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

- (void)start;
{
	//Call setup on all patches
	//TODO: support setup on sub-nodes
	[self _setupRecursive:rootObject];
	
	previousAbsoluteTime = CFAbsoluteTimeGetCurrent();
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
	BOOL ok = [inPatch getTopologicalOrdering:&executionOrdering andExcludedEdges:&excludedEdges];
	if (ok) {
		return executionOrdering;
	} else {
		return nil;
	}
}

#pragma -

+ (GLKMatrix4)cameraMatrixWithRect:(CGRect)inBounds;
{
	GLKMatrix4 cameraMatrix;
		
	const float near = 0.1;
	const float far = 10.0;
	
	const float aspectRatio = inBounds.size.height / inBounds.size.width;
	
	const float eyeZ = 3.0f; //rsl / nearZ
	
	const float scale = near / eyeZ;
	
	//GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(viewAngle, aspectRatio, near, far);
	GLKMatrix4 projectionMatrix = GLKMatrix4MakeFrustum(-scale, scale, -scale * aspectRatio, scale * aspectRatio, near, far);
	
	//glDepthRangef(near, far);
	
	const GLKVector3 cameraPosition = {0, 0, eyeZ};
	const GLKVector3 cameraTarget = {0, 0, 0};
	const GLKVector3 upVec = {0, 1, 0};
	
	GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
												   cameraTarget.x,   cameraTarget.y,   cameraTarget.z,
												          upVec.x,          upVec.y,          upVec.z);
	
	cameraMatrix = projectionMatrix * viewMatrix;
	
#if DEBUG_LOG_RENDER_MATRICES
	
	NSLog(@"Perspective: %@", NSStringFromGLKMatrix4(projectionMatrix));
	
	NSLog(@"Look At: %@", NSStringFromGLKMatrix4(viewMatrix));
	
	NSLog(@"Final: %@", NSStringFromGLKMatrix4(cameraMatrix));
	
	NSLog(@"Position of 0,0,0 in screen space: %@", NSStringFromGLKVector3(GLKMatrix4MultiplyVector3(cameraMatrix, (GLKVector3){0,0,0})));

	NSLog(@"Position of 1,1,0 in screen space: %@", NSStringFromGLKVector3(GLKMatrix4MultiplyVector3(cameraMatrix, (GLKVector3){1,1,0})));
	
#endif
	
	return cameraMatrix;
}


- (WMConnection *)connectionToInputPort:(WMPort *)inPort ofNode:(WMPatch *)inPatch inParent:(WMPatch *)inParent;
{
	for (WMConnection *connection in inParent.connections) {
		if ([connection.destinationNode isEqualToString:inPatch.key] && [connection.destinationPort isEqualToString:inPort.key]) {
			//Find the source node
			//TODO: optimize the order of this
			return connection;
		}
	}
	return nil;
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
			if (!connection) continue;
			WMPatch *sourcePatch = [inPatch patchWithKey:connection.sourceNode];
			WMPort *sourcePort = [sourcePatch outputPortWithKey:connection.sourcePort];
			[inputPort takeValueFromPort:sourcePort];
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

}

- (void)drawFrameInRect:(CGRect)inBounds interfaceOrientation:(UIInterfaceOrientation)inInterfaceOrientation;
{
	//Pass along the device orientation. This is necessary for patches whose semantics are dependent on which direction is "up" for the user.
	//Examples: accelerometer, camera input.
	[compositionUserData setObject:[NSNumber numberWithInt:inInterfaceOrientation] forKey:WMEngineArgumentsInterfaceOrientationKey];
	if (document) {
		[compositionUserData setObject:document forKey:WMEngineArgumentsDocumentKey];
	}
	
	
	//Make sure we have set up all new node
	[self _setupRecursive:self.rootObject];
	
	//Clear out the rendering context
	[renderContext clearToColor:(GLKVector4){0, 0, 0, 1}];
	[renderContext clearDepth];

	renderContext.modelViewMatrix = [WMEngine cameraMatrixWithRect:inBounds];
	
	//// Time         ////
	//TODO: support pause / resume
	CFAbsoluteTime currentAbsoluteTime = CFAbsoluteTimeGetCurrent();
	t += currentAbsoluteTime - previousAbsoluteTime;
	previousAbsoluteTime = currentAbsoluteTime;
	
	[self drawPatchRecursive:self.rootObject];
}


- (NSString *)title;
{
	return @"TITLE HERE";
}

@end
