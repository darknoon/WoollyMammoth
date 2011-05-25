//
//  DNQCComposition.m
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "DNQCComposition.h"

#import "WMPatch.h"

NSString *DNQCCompositionErrorDomain = @"com.darknoon.DNQCComposition";

NSString *DNQCCompositionPlistKeyRootPatch = @"rootPatch";

@interface DNQCComposition()

@end

@implementation DNQCComposition
@synthesize userDictionary;

- (id)initWithContentsOfFile:(NSString *)inFile error:(NSError **)outError;
{
	self = [super init];
	if (!self) return nil;
	
	plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:inFile];
	if (!plistDictionary) {
		if (outError)
			*outError = [NSError errorWithDomain:DNQCCompositionErrorDomain code:DNQCCompositionErrorFileError userInfo:nil];
		[self release];
		return nil;
	}
	compositionBasePath = [[inFile stringByDeletingLastPathComponent] retain];
	
	return self;
}

- (void)dealloc {
    [plistDictionary release];
    [super dealloc];
}

- (WMPatch *)rootPatch;
{
	if (!rootPatch) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSDictionary *graphRep = [plistDictionary objectForKey:@"rootPatch"];
		if (graphRep) {
			rootPatch = [[WMPatch patchWithPlistRepresentation:graphRep] retain];
			//Set input params
			NSDictionary *inputParameters = [plistDictionary objectForKey:@"inputParameters"];
			[inputParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
				WMPort *inputPort = [rootPatch inputPortWithKey:key];
				BOOL success = [inputPort setStateValue:value];
				if (!inputPort || !success) {
					NSLog(@"Couldn't set value of input port %@", key);
				}
			}];

		}
		[pool drain];
	}
	return rootPatch;
}

//None of these will be added to the userDictionary
- (NSSet *)qcKeys;
{
	return [NSSet setWithObjects:@"rootPatch", @"virtualPatches",@"frameworkVersion",@"portAttributes", nil];
}

- (NSDictionary *)userDictionary;
{
	if (!userDictionary) {
		NSMutableDictionary *userDictionaryMutable = [[NSMutableDictionary alloc] initWithDictionary:plistDictionary];
		[userDictionaryMutable removeObjectsForKeys:[[self qcKeys] allObjects]];
		[userDictionaryMutable setObject:compositionBasePath forKey:WMCompositionPathKey];
		userDictionary = [userDictionaryMutable copy];
		[userDictionaryMutable release];
	}
	return userDictionary;
}

- (NSString *)frameworkVersion;
{
	return [plistDictionary objectForKey:@"frameworkVersion"];
}

@end
