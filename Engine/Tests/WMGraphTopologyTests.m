//
//  WMGraphTopologyTests.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/4/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMGraphTopologyTests.h"

#import "WMEngine.h"
#import "WMPatch.h"

@implementation WMGraphTopologyTests {
	WMPatch *root;
	WMEngine *e;
}


//Generic patch, generic ports.
- (WMPatch *)patchWithKey:(NSString *)inKey inputPorts:(NSArray *)inputPortKeys outputPorts:(NSArray *)outputPortKeys;
{
	WMPatch *patch = [[[WMPatch alloc] initWithPlistRepresentation:nil] autorelease];
	patch.key = inKey;
	
	for (NSString *key in inputPortKeys) {
		WMPort *p = [WMPort portWithKey:key];
		[patch addInputPort:p];
	}

	for (NSString *key in outputPortKeys) {
		WMPort *p = [WMPort portWithKey:key];
		[patch addOutputPort:p];
	}
	
	return patch;
}

- (void)addBasicPatchWithKey:(NSString *)inKey;
{
	WMPatch *p = [self patchWithKey:inKey inputPorts:[NSArray arrayWithObjects:@"i", nil] outputPorts:[NSArray arrayWithObjects:@"o", nil]];
	[root addChild:p];
}


//Connects "o" to "i"
- (void)connectOutputOfPatch:(NSString *)inOutputPatchKey toInputOfPatch:(NSString *)inInputPatchKey;
{
	[root addConnectionFromPort:@"o" ofPatch:inOutputPatchKey toPort:@"i" ofPatch:inInputPatchKey];
}

- (void)setUp;
{
	root = [[self patchWithKey:@"_root" inputPorts:nil outputPorts:nil] retain];
	e = [[WMEngine alloc] initWithRootObject:root userData:nil];

}

- (void)tearDown;
{
	[e release];
	[root release];
}


- (void)testGenericPatch;
{
	WMPatch *patch = [self patchWithKey:@"blah" inputPorts:[NSArray arrayWithObjects:@"a", @"b", @"c", nil] outputPorts:[NSArray arrayWithObjects:@"d", @"e", nil]];
	
	STAssertEqualObjects(patch.key, @"blah", @"Key does not match");
	STAssertNotNil([patch inputPortWithKey:@"a"], @"Input port not created");	
}



- (void)testBasicOrdering;
{
	
	//Simple graph A -> B -> C
	
	WMPatch *a = [self patchWithKey:@"a" inputPorts:[NSArray arrayWithObjects:@"i", nil] outputPorts:[NSArray arrayWithObjects:@"o", nil]];
	[root addChild:a];
	
	WMPatch *b = [self patchWithKey:@"b" inputPorts:[NSArray arrayWithObjects:@"i", nil] outputPorts:[NSArray arrayWithObjects:@"o", nil]];
	[root addChild:b];

	WMPatch *c = [self patchWithKey:@"c" inputPorts:[NSArray arrayWithObjects:@"i", nil] outputPorts:[NSArray arrayWithObjects:@"o", nil]];
	[root addChild:c];
	
	[root addConnectionFromPort:@"o" ofPatch:@"a" toPort:@"i" ofPatch:@"b"];
	[root addConnectionFromPort:@"o" ofPatch:@"b" toPort:@"i" ofPatch:@"c"];
		
	STAssertNotNil(e, @"Engine creation");
	
	NSArray *executionOrder = [e executionOrderingOfChildren:root];
	NSArray *expectedOrder = [NSArray arrayWithObjects:a, b, c, nil];
	STAssertEqualObjects(executionOrder, expectedOrder, @"Execution order incorrect");
}


/*
 * Graph looks like
 * A -> B ----> C 
 *      D -/
 */
- (void)testBranchingGraph;
{
	for (NSString *key in [NSArray arrayWithObjects:@"a", @"b", @"d", nil]) {
		[self addBasicPatchWithKey:key];
	}
	
	WMPatch *c = [self patchWithKey:@"c" inputPorts:[NSArray arrayWithObjects:@"i0", @"i1", nil] outputPorts:nil];
	[root addChild:c];

	[self connectOutputOfPatch:@"a" toInputOfPatch:@"b"];
	
	[root addConnectionFromPort:@"o" ofPatch:@"b" toPort:@"i0" ofPatch:@"c"];
	[root addConnectionFromPort:@"o" ofPatch:@"d" toPort:@"i1" ofPatch:@"c"];
	
	NSArray *executionOrderKeys = [[e executionOrderingOfChildren:root] valueForKey:@"key"];
	
	NSSet *expected = [NSSet setWithObjects:@"a", @"b", @"c", @"d", nil];
	STAssertEqualObjects([NSSet setWithArray:executionOrderKeys], expected, @"Not all objects will execute: %@", executionOrderKeys);
	
	//Assert that a is before b, b is before c, and d is before c
	STAssertTrue([executionOrderKeys indexOfObject:@"a"] < [executionOrderKeys indexOfObject:@"b"], @"a before b %@", executionOrderKeys);
	STAssertTrue([executionOrderKeys indexOfObject:@"b"] < [executionOrderKeys indexOfObject:@"c"], @"b before c %@", executionOrderKeys);
	STAssertTrue([executionOrderKeys indexOfObject:@"d"] < [executionOrderKeys indexOfObject:@"c"], @"d before c %@", executionOrderKeys);
}

/*
 * Graph looks like
 *  A -----> B -> C -> D
 *       /        |
 *       +--------+
 */
- (void)testCyclicGraph;
{
	//TODO: this test
	
	//We should get either ([A, B, C, D], {CB}), ([A, C, B, D], {BC}), ([C, A, B, D], {BC}), ([A, C, D, B], {BC}), ([C, A, B, D], {BC})
	for (NSString *key in [NSArray arrayWithObjects:@"a", @"c", @"d", nil]) {
		[self addBasicPatchWithKey:key];
	}
	WMPatch *b = [self patchWithKey:@"b" inputPorts:[NSArray arrayWithObjects:@"i0", @"i1", nil] outputPorts:nil];
	[root addChild:b];
	
	
	
}

@end
