//
//  WMPatch+GraphAlgorithms.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/4/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch+GraphAlgorithms.h"

#import "WMConnection.h"

@implementation WMPatch (WMPatch_GraphAlgorithms)

- (BOOL)childPatchHasIncomingEdges:(WMPatch *)inPatch connections:(NSArray *)inConnections excludedConnections:(NSSet *)inExcludedConnections;
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

- (BOOL)childPatchHasOutgoingEdges:(WMPatch *)inPatch connections:(NSArray *)inConnections;
{
	for (WMConnection *connection in inConnections) {
		if ([connection.sourceNode isEqualToString:inPatch.key]) {
			return YES;
		}
	}
	return NO;
}

//http://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
- (void)_searchForStronglyConnectedComponentsWithVertexIndices:(NSMutableDictionary *)inVertexIndices vertexLowLinks:(NSMutableDictionary *)inVertexLowLinks currentIndex:(inout int **)inOutIndex;
{
	//TODO!
}

- (NSArray *)stronglyConnectedComponents;
{
	//TODO!
	//TODO: speed this up with c++ data structures
	NSMutableDictionary *vertexIndices = [NSMutableDictionary dictionaryWithCapacity:self.children];
	NSMutableDictionary *vertexLowLinks = [NSMutableDictionary dictionaryWithCapacity:self.children];
	
	return [NSArray array];
}

//This only supports children of a node NOT sub-children for now!!
//Perhaps use an iterator aka NSEnumerator?
- (BOOL)getTopologicalOrdering:(NSArray **)outTopologicalSort andExcludedEdges:(NSSet **)outExcludedEdges;
{
	//TODO: reduce complexity of this method
	//TODO: define this algorithm formally
    
	//The following while loop will only apply to these nodes
	NSSet *childSet = [NSSet setWithArray:self.children];
    
	NSMutableSet *hiddenEdges = [NSMutableSet set]; //hidden WMConnecitions
	
	NSMutableArray *sorted = [NSMutableArray array];
	NSMutableSet *noIncomingEdgeNodeSet = [NSMutableSet set];
	//Add starting set of nodes with no incoming edges
	for (WMPatch *node in self.children) {
		if ([childSet containsObject:node] && ![self childPatchHasIncomingEdges:node connections:self.connections excludedConnections:hiddenEdges]) {
			[noIncomingEdgeNodeSet addObject:node];		
		}
	}
    
	while (noIncomingEdgeNodeSet.count > 0) {
		WMPatch *n = [noIncomingEdgeNodeSet anyObject];
		[noIncomingEdgeNodeSet removeObject:n];
		[sorted addObject:n];
		
		//for each node m with an edge e from n to m do
		for (WMConnection *e in self.connections) {
			if (![hiddenEdges containsObject:e]) {
				
				//If this is an edge from e to m
				if ([e.sourceNode isEqualToString:n.key]) {
					WMPatch *m = [self patchWithKey:e.destinationNode];
					NSAssert1(m, @"Couldn't find connected node %@", e.destinationNode);
					[hiddenEdges addObject:e];
					
					//if m has no other incoming edges then
					//TODO: also check if m has nodes that need to go before it
					if ([childSet containsObject:m] && ![self childPatchHasIncomingEdges:m connections:self.connections excludedConnections:hiddenEdges]) {
						// insert m into S
						[noIncomingEdgeNodeSet addObject:m];
					}
				}
			}
		}
	}
	
	//Now add consumer nodes (in render order!)
	for (WMPatch *patch in self.children) {
		if (![childSet containsObject:patch]) {
			[sorted addObject:patch];
		}
	}
	
	//TODO: assert all connections are hidden (graph has at least one cycle)
	
	if (outTopologicalSort) *outTopologicalSort = [[sorted copy] autorelease];
	//TODO: implement cycle exclusion!
	if (outExcludedEdges) *outExcludedEdges = [NSSet set];
	
	return YES;
}



@end
