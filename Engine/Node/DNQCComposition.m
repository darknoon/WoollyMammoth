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
	
	
	
	return self;
}

- (void)dealloc {
    [plistDictionary release];
    [super dealloc];
}

- (WMPatch *)rootPatch;
{
	if (!rootPatch) {
		NSDictionary *graphRep = [plistDictionary objectForKey:@"rootPatch"];
		if (graphRep) {
			rootPatch = [[WMPatch patchWithPlistRepresentation:graphRep] retain];
		}
	}
	return rootPatch;
}

- (NSString *)frameworkVersion;
{
	return [plistDictionary objectForKey:@"frameworkVersion"];
}

@end
