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


//See this http://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm for a description of the algorithm.
//Reference for algorithm: http://en.wikipedia.org/w/index.php?title=Tarjan%27s_strongly_connected_components_algorithm&oldid=438785712#The_algorithm_in_pseudocode
- (void)_searchForStronglyConnectedComponentsWithVertex:(WMPatch *)inV
										  vertexIndices:(NSMutableDictionary *)inOutVertexIndices
										 vertexLowLinks:(NSMutableDictionary *)inOutVertexLowLinks
										   currentIndex:(inout int *)inOutIndex
												  stack:(NSMutableArray *)inOutStack
							  outputConnectedComponents:(NSMutableArray *)inOutConnectedComponents;
{
	[inOutVertexIndices  setObject:[NSNumber numberWithInt:*inOutIndex] forKey:inV.key];
	[inOutVertexLowLinks setObject:[NSNumber numberWithInt:*inOutIndex] forKey:inV.key];
	(*inOutIndex)++;
	[inOutStack addObject:inV];
	
	// Consider successors of v
	for (WMConnection *connection in self.connections) {
		if ([connection.sourceNode isEqualToString:inV.key]) {
			WMPatch *w = [childrenByKey objectForKey:connection.destinationNode];
			if (w && [inOutVertexIndices objectForKey:w.key] == nil) {
				// Successor w has not yet been visited; recurse on it
				[self _searchForStronglyConnectedComponentsWithVertex:w
														vertexIndices:inOutVertexIndices
													   vertexLowLinks:inOutVertexLowLinks
														 currentIndex:inOutIndex
																stack:inOutStack
											outputConnectedComponents:inOutConnectedComponents];
				NSNumber *vLowLink = [inOutVertexLowLinks objectForKey:inV.key];
				NSNumber *wLowLink = [inOutVertexLowLinks objectForKey:w.key];
				ZAssert(vLowLink && wLowLink, @"Undefined low link!");
				NSNumber *newVLowLink = [NSNumber numberWithInt:MIN([vLowLink intValue], [wLowLink intValue])];
				[inOutVertexLowLinks setObject:newVLowLink forKey:inV.key];
			} else if (w && [inOutStack containsObject:w]) {
				// Successor w is in stack S and hence in the current SCC
				NSNumber *vLowLink = [inOutVertexLowLinks objectForKey:inV.key];
				NSNumber *wIndex = [inOutVertexIndices objectForKey:w.key];
				ZAssert(vLowLink && wIndex, @"Undefined low link or index");
				NSNumber *newVLowLink = [NSNumber numberWithInt:MIN([vLowLink intValue], [wIndex intValue])];
				[inOutVertexLowLinks setObject:newVLowLink forKey:inV.key];
			}
		}
	}

	// If v is a root node, pop the stack and generate an SCC
	NSNumber *vLowLink = [inOutVertexLowLinks objectForKey:inV.key];
	NSNumber *vIndex = [inOutVertexIndices objectForKey:inV.key];
	ZAssert(vLowLink && vIndex, @"Couldn't find low link or index for v:%@", inV.key);
	if ([vLowLink intValue] == [vIndex intValue]) {
		//start a new strongly connected component
		NSMutableArray *newComponent = [NSMutableArray array];
		WMPatch *w = nil;
		do {
			ZAssert(inOutStack.count > 0, @"hmm, stack not the right size");
			w = [inOutStack objectAtIndex:inOutStack.count - 1];
			[inOutStack removeLastObject];
			[newComponent addObject:w];
		} while (w != inV);
		if (newComponent.count > 1)
			[inOutConnectedComponents addObject:newComponent];
	}
}

//Running time should be O( children.count + connections.count )
//Some caveats would be that "The test for whether v' is on the stack should be done in constant time", which is not actually true here. ~ln(children.count)
- (NSArray *)stronglyConnectedComponents;
{
	//TODO: speed this up with c++ data structures
	//Map of patch => index
	NSMutableDictionary *vertexIndices = [NSMutableDictionary dictionaryWithCapacity:self.children.count];
	//Map of patch => lowLink
	NSMutableDictionary *vertexLowLinks = [NSMutableDictionary dictionaryWithCapacity:self.children.count];
	
	NSMutableArray *outputConnectedComponents = [NSMutableArray array];
	NSMutableArray *stack = [NSMutableArray array];
	
	int idx = 0;
	
	for (WMPatch *v in self.children) {
		if ([vertexIndices objectForKey:v] == nil) {
			[self _searchForStronglyConnectedComponentsWithVertex:v
													vertexIndices:vertexIndices
												   vertexLowLinks:vertexLowLinks
													 currentIndex:&idx
															stack:stack
										outputConnectedComponents:outputConnectedComponents];
		}
	}
	
	return outputConnectedComponents;
}

//This only supports children of a node NOT sub-children for now!!
//Perhaps use an iterator aka NSEnumerator?
- (BOOL)getTopologicalOrdering:(NSArray **)outTopologicalSort andExcludedEdges:(NSSet **)outExcludedEdges;
{
	//TODO: reduce complexity of this method
	//TODO: define this algorithm formally
    
	//The following while loop will only apply to these nodes
	NSSet *childSet = [NSSet setWithArray:self.children];
    
	
	//Find the connected components, and exclude all edges of the first link of each.
	//Does this do what we want if the topology is weird in terms of multiple edges?
	NSArray *cycles = [self stronglyConnectedComponents];
	NSMutableSet *excludedEdges = [NSMutableSet set];
	for (NSArray *cycle in cycles) {
		//Exclude all edges from the first to the second
		WMPatch *first = [cycle objectAtIndex:0];
		WMPatch *second = [cycle objectAtIndex:1];
		for (WMConnection *connection in self.connections) {
			if ([connection.sourceNode isEqualToString:first.key] && [connection.destinationNode isEqualToString:second.key]) {
				[excludedEdges addObject:connection];
			}
		}
	}
	
	NSMutableSet *hiddenEdges = [NSMutableSet setWithSet:excludedEdges]; //hidden WMConnecitions
	
	
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
	
	sorted = [sorted copy];
	excludedEdges = [excludedEdges copy];
	
	if (outTopologicalSort) *outTopologicalSort = sorted;
	//TODO: implement cycle exclusion!
	if (outExcludedEdges) *outExcludedEdges = excludedEdges;
	
	return YES;
}



@end
