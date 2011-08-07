//
//  WMPatch+GraphAlgorithms.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/4/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMPatch (WMPatch_GraphAlgorithms)

//Returns an array of arrays of strongly connected components via Tarjan's algorithm. This is used to exclude edges in the topological sorting below.
- (NSArray *)stronglyConnectedComponents;

//The patch graph may or may not be sortable topologically. If it is not sortable, this method will return excluded edges
- (BOOL)getTopologicalOrdering:(NSArray **)outTopologicalSort andExcludedEdges:(NSSet **)outExcludedEdges;

- (BOOL)childPatchHasIncomingEdges:(WMPatch *)inPatch connections:(NSArray *)inConnections excludedConnections:(NSSet *)inExcludedConnections;
- (BOOL)childPatchHasOutgoingEdges:(WMPatch *)inPatch connections:(NSArray *)inConnections;

@end
