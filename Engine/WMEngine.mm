//
//  WMEngine.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMEngine.h"

#import "Matrix.h"

#import "WMPatch.h"
#import "WMConnection.h"
#import "WMPort.h"

#import "WMEAGLContext.h"
#import "DNFramebuffer.h"
#import "DNQCComposition.h"


@interface WMEngine ()
@property (nonatomic, retain, readwrite) WMPatch *rootObject;

@end


@implementation WMEngine

@synthesize renderContext;
@synthesize rootObject;

- (id) init {
	self = [super init];
	if (self == nil) return self; 
	
	patchesByKey = [[NSMutableDictionary alloc] initWithCapacity:256];
	renderContext = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

	return self;
}


- (void)dealloc
{
	//TODO: expose the idea of cleanup outside of -dealloc
	//Call cleanup on all patches
	//TODO: support cleanup on sub-nodes
	for (WMPatch *patch in rootObject.children) {
		//This could be done with an "enumerate children recursive with block"
		[patch cleanup:renderContext];
	}
	
	[rootObject release];
	[patchesByKey release];
	[renderContext release];

	[super dealloc];
}

- (void)debugMakeObjectGraph;
{
}

- (void)_addPatchesToPatchesByKeyRecursive:(WMPatch *)inPatch;
{
	if (inPatch.key)
		[patchesByKey setObject:inPatch forKey:inPatch.key];
	for (WMPatch *child in inPatch.children) {
		[self _addPatchesToPatchesByKeyRecursive:child];
	}
}

- (void)start;
{
	NSString *debugFilePath = [[NSBundle mainBundle] pathForResource:@"BasicCamera" ofType:@"qtz"];
//	NSString *debugFilePath = [[NSBundle mainBundle] pathForResource:@"BasicColor" ofType:@"qtz"];
	
	//Deserialize object graph	
	NSError *sceneReadError = nil;
	DNQCComposition *composition = [[DNQCComposition alloc] initWithContentsOfFile:debugFilePath error:&sceneReadError];

	self.rootObject = composition.rootPatch;	
	
	//Setup patches by key
	[self _addPatchesToPatchesByKeyRecursive:composition.rootPatch];
	
	//Call setup on all patches
	//TODO: support setup on sub-nodes
	for (WMPatch *patch in rootObject.children) {
		//This could be done with an "enumerate children recursive with block"
		[patch setup:renderContext];
	}
	
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

- (BOOL)_nodeHasIncomingEdges:(WMPatch *)inPatch connections:(NSArray *)inConnections excludedConnections:(NSSet *)inExcludedConnections;
{
	for (WMConnection *connection in inConnections) {
		if (![inExcludedConnections containsObject:connection]) {
			if ([connection.destinationNode isEqualToString:inPatch.key]) {
				return YES;
			}
		}
	}
	return NO;
}

- (BOOL)_nodeHasOutgoingEdges:(WMPatch *)inPatch connections:(NSArray *)inConnections;
{
	for (WMConnection *connection in inConnections) {
		if ([connection.sourceNode isEqualToString:inPatch.key]) {
			return YES;
		}
	}
	return NO;
}

//TODO: make this way more efficent!
- (WMPatch *)_firstRenderingNodeInSet:(NSSet *)inNodeSet orderedNodes:(NSArray *)inOrderedNodes;
{
	NSUInteger minIndex = UINT32_MAX;
	WMPatch *minPatch = nil;
	for (WMPatch *patch in inNodeSet) {
		NSUInteger i = [inOrderedNodes indexOfObject:patch];
		if (i < minIndex) {
			i = minIndex;
			minPatch = patch;
		}
	}
	return minPatch;
}

//Execute all of these first
- (NSMutableSet *)_nonConsumerNodesInNodes:(NSArray *)inNodes connections:(NSArray *)inConnections;
{
	NSMutableSet *outSet = [NSMutableSet set];
	for (WMPatch *patch in inNodes) {
		if ([self _nodeHasOutgoingEdges:patch connections:inConnections]) {
			[outSet addObject:patch];
		}
	}
	return outSet;
}

//This only supports children of a node NOT sub-children for now!!
//Perhaps use an iterator aka NSEnumerator?
- (NSArray *)executionOrderingOfChildren:(WMPatch *)inPatch;
{
	//TODO: reduce complexity of this method
	//TODO: define this algorithm formally

	//The following while loop will only apply to these nodes
	NSSet *nonConsumerNodes = [self _nonConsumerNodesInNodes:inPatch.children connections:inPatch.connections];

	NSMutableSet *hiddenEdges = [NSMutableSet set]; //hidden WMConnecitions
	
	NSMutableArray *sorted = [NSMutableArray array];
	NSMutableSet *noIncomingEdgeNodeSet = [NSMutableSet set];
	//Add starting set of no-incoming-edges-and-not-consumer nodes o_O
	for (WMPatch *node in inPatch.children) {
		if ([nonConsumerNodes containsObject:node] && ![self _nodeHasIncomingEdges:node connections:inPatch.connections excludedConnections:hiddenEdges]) {
			[noIncomingEdgeNodeSet addObject:node];		
		}
	}
		
	while (noIncomingEdgeNodeSet.count > 0) {
		WMPatch *n = [self _firstRenderingNodeInSet:noIncomingEdgeNodeSet orderedNodes:inPatch.children]; //TODO: require nodes with lower rendering order to be rendered first
		[noIncomingEdgeNodeSet removeObject:n];
		[sorted addObject:n];
		
		//for each node m with an edge e from n to m do
		for (WMConnection *e in inPatch.connections) {
			if (![hiddenEdges containsObject:e]) {
				
				//If this is an edge from e to m
				if ([e.sourceNode isEqualToString:n.key]) {
					WMPatch *m = [self patchWithKey:e.destinationNode];
					NSAssert1(m, @"Couldn't find connected node %@", e.destinationNode);
					[hiddenEdges addObject:e];
					
					//if m has no other incoming edges then
					//TODO: also check if m has nodes that need to go before it
					if ([nonConsumerNodes containsObject:m] && ![self _nodeHasIncomingEdges:m connections:inPatch.connections excludedConnections:hiddenEdges]) {
						// insert m into S
						[noIncomingEdgeNodeSet addObject:m];
					}
				}
			}
		}
	}
	
	//Now add consumer nodes (in render order!)
	for (WMPatch *patch in inPatch.children) {
		if (![nonConsumerNodes containsObject:patch]) {
			[sorted addObject:patch];
		}
	}
	
	//TODO: assert all connections are hidden (graph has at least one cycle)
	return sorted;
}


#pragma -

- (MATRIX)cameraMatrixWithRect:(CGRect)inBounds;
{
	MATRIX cameraMatrix;
	//TODO: move this state setting to WMEAGLContext
	//glCullFace(GL_BACK);
	
	MATRIX projectionMatrix;
	GLfloat viewAngle = 35.f * M_PI / 180.0f;
	
	const float near = 0.1;
	const float far = 1000.0;
	
	const float aspectRatio = inBounds.size.width / inBounds.size.height;
	
	MatrixPerspectiveFovRH(projectionMatrix, viewAngle, aspectRatio, near, far, NO);
	
	//glDepthRangef(near, far);
	
	MATRIX viewMatrix;
	Vec3 cameraPosition(0, 0, 3.0f);
	Vec3 cameraTarget(0, 0, 0);
	Vec3 upVec(0, 1, 0);
	MatrixLookAtRH(viewMatrix, cameraPosition, cameraTarget, upVec);
	
	MatrixMultiply(cameraMatrix, viewMatrix, projectionMatrix);
	
#if DEBUG_LOG_RENDER_MATRICES
	
	NSLog(@"Perspective: ");
	MatrixPrint(projectionMatrix);
	
	NSLog(@"Look At: ");
	MatrixPrint(viewMatrix);
	
	NSLog(@"Final: ");
	MatrixPrint(cameraMatrix);
	
	Vec3 position(0,0,0);
	MatrixVec3Multiply(position, position, cameraMatrix);
	NSLog(@"Position of 0,0,0 in screen space: %f %f %f", position.x, position.y, position.z);
	
	position = Vec3(1,1,0);
	MatrixVec3Multiply(position, position, cameraMatrix);
	NSLog(@"Position of 1,1,0 in screen space: %f %f %f", position.x, position.y, position.z);
#endif
	
	return cameraMatrix;
}

- (WMConnection *)connectionToInputPort:(WMPort *)inPort ofNode:(WMPatch *)inPatch;
{
	for (WMConnection *connection in rootObject.connections) {
		if ([connection.destinationNode isEqualToString:inPatch.key] && [connection.destinationPort isEqualToString:inPort.name]) {
			//Find the source node
			//TODO: optimize the order of this
			return connection;
		}
	}
	return nil;
}

- (void)drawFrameInRect:(CGRect)inBounds;
{
	//TODO: abstract this state out
	glViewport(0, 0, renderContext.boundFramebuffer.framebufferWidth, renderContext.boundFramebuffer.framebufferHeight);

	MATRIX modelViewMatrix = [self cameraMatrixWithRect:inBounds];
	
	[renderContext setModelViewMatrix:modelViewMatrix.f];
	
	//// Time         ////
	//TODO: support pause / resume
	CFAbsoluteTime currentAbsoluteTime = CFAbsoluteTimeGetCurrent();
	t += currentAbsoluteTime - previousAbsoluteTime;
	previousAbsoluteTime = currentAbsoluteTime;
	
	//// Render order ////
	//TODO: generalize to take values from the input ports
	NSArray *ordering = [self executionOrderingOfChildren:self.rootObject];
		
	//// Render       ////
	BOOL success = YES;
	for (WMPatch *patch in ordering) {
		//Write the values of the input ports from the output ports of the connections
		for (WMPort *inputPort in [patch ivarInputPorts]) {
			//TODO: keep a record of what connections are connected to what ports for efficency here
			//Find a connection to this input port
			WMConnection *connection = [self connectionToInputPort:inputPort ofNode:patch];
			if (!connection) continue;
			WMPatch *sourcePatch = [self patchWithKey:connection.sourceNode];
			WMPort *sourcePort = [sourcePatch outputPortWithName:connection.sourcePort];
			[inputPort takeValueFromPort:sourcePort];
		}
		success = [patch execute:renderContext time:t arguments:nil];
		if (!success) {
			NSLog(@"Error executing patch: %@", patch);
			break;
		}
	}
}


- (WMPatch *)patchWithKey:(NSString *)inPatchKey;
{
	return [patchesByKey objectForKey:inPatchKey];
}

- (NSString *)title;
{
	return @"TITLE HERE";
}

@end
