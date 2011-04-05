//
//  WMGameObject.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMGameObject.h"

//Temporary, move this out to a smarter place
#import "WMRenderable.h"

#import "WMEngine.h"
#import "WMLuaScript.h"

@implementation WMGameObject

@synthesize script;
@synthesize transform;
@synthesize renderable;
@synthesize notes;
@synthesize objectId;
@synthesize parent;

- (id)initWithObjectId:(UInt64)inObjectId inEngine:(WMEngine *)inEngine;
{
	self = [self init];
	if (self == nil) return self; 
	
	engine = inEngine;
	
	objectId = inObjectId;
	mutableChildren = [[NSMutableArray alloc] init];
	notes = @"";
	
	MatrixIdentity(transform);
		
	return self;
}

- (void)dealloc
{	
	[notes release];
	[mutableChildren release];	
	
	[renderable release];

	[script release];
	script = nil;

	[super dealloc];
}

#pragma mark -
#pragma mark Hierarchy Managment

- (void)removeFromParent;
{
	[parent removeChild:self];
}

- (void)addChild:(WMGameObject *)inChild;
{
	[inChild retain];
	[inChild removeFromParent];
	[mutableChildren addObject:inChild];
	inChild.parent = self;
	[inChild release];
}

- (void)removeChild:(WMGameObject *)inChild;
{
	[mutableChildren removeObject:inChild];
}

- (NSArray *)children;
{
	return [[mutableChildren copy] autorelease];
}

#pragma mark -
#pragma mark Update

- (void)update;
{
	//Run relevant script
	//TODO: make this efficent
	if (script) {
		[script executeInScriptingContext:engine.scriptingContext thisObject:self];
	}
	
	if (renderable) {
		[renderable update];
	}
	
}

#pragma mark -

- (NSString *)description;
{
	return [[super description] stringByAppendingFormat:@"{\"%@\", %d childen}", notes, mutableChildren.count];
}

- (NSString *)descriptionRecursive;
{
	NSMutableString *descriptionRecursive = [NSMutableString stringWithString:[self description]];
	for (WMGameObject *child in mutableChildren) {
		[descriptionRecursive appendFormat:@"\n\t%@", [child descriptionRecursive]];
	}
	[descriptionRecursive appendString:@"\n"];
	return descriptionRecursive;
}

@end
