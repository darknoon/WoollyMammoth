//
//  WMComposition.m
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCompositionSerialization.h"

#import "WMPatch.h"

NSString *WMCompositionUserInfoVersionKey = @"frameworkVersion";

NSString *WMCompositionKeyRootPatch = @"rootPatch";

//TODO: can't this be accomplished just by the root patch doing the normal patch thing?
//NSString *WMCompositionKeyInputParameters = @"inputParameters";

NSString *WMCompositionFrameworkVersion = @"0.1";

@interface WMCompositionSerialization()

@end

@implementation WMCompositionSerialization

//None of these will be added to the userDictionary
+ (NSSet *)standardKeys;
{
	return [NSSet setWithObjects:@"rootPatch", @"inputParameters", nil];
}

+ (WMPatch *)patchWithPlistDictionary:(NSDictionary *)inPlistDictionary compositionBasePath:(NSString *)inBasePath userDictionary:(NSDictionary **)outUserDictionary error:(NSError **)outError;
{
	WMPatch *rootPatch = nil;
	NSDictionary *graphRep = [inPlistDictionary objectForKey:WMCompositionKeyRootPatch];
	if (graphRep) {
		rootPatch = [WMPatch patchWithPlistRepresentation:graphRep];
		
		if (rootPatch) {
			//Set input params
//			NSDictionary *inputParameters = [inPlistDictionary objectForKey:WMCompositionKeyInputParameters];
//			[inputParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
//				WMPort *inputPort = [rootPatch inputPortWithKey:key];
//				BOOL success = [inputPort setStateValue:value];
//				if (!inputPort || !success) {
//					NSLog(@"Couldn't set value of input port %@", key);
//				}
//			}];
			
			if (outUserDictionary) {
				NSMutableDictionary *userDictionaryMutable = [[NSMutableDictionary alloc] initWithDictionary:inPlistDictionary];
				[userDictionaryMutable removeObjectsForKeys:[[self standardKeys] allObjects]];
				*outUserDictionary = [userDictionaryMutable copy];
				[userDictionaryMutable release];
			}
		} else {
			//TODO: return root object deserialization error
		}
		
	}
	return rootPatch;
}

+ (NSDictionary *)plistDictionaryWithRootPatch:(WMPatch *)inPatch userDictionary:(NSDictionary *)inUserDictionary error:(NSError **)outError;
{
	NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionary];
	
	NSDictionary *rootPatch = [inPatch plistRepresentation];
	if (!rootPatch) {
		//TODO: return error!
		return nil;
	}
	if (![NSPropertyListSerialization propertyList:rootPatch isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
		NSLog(@"Root patch contains things that cannot be serialized into a binary plist. :%@", rootPatch);
		return nil;
	}
	
	[plistDictionary setObject:rootPatch forKey:WMCompositionKeyRootPatch];
	
	NSMutableDictionary *userDictionary = [inUserDictionary mutableCopy];
	//Make sure the user dictionary never can override our built-in keys
	[userDictionary removeObjectsForKeys:[[self standardKeys] allObjects]];
	[plistDictionary addEntriesFromDictionary:userDictionary];
	[userDictionary release];
	
	//Save our framework version
	[plistDictionary setObject:WMCompositionFrameworkVersion forKey:WMCompositionUserInfoVersionKey];
	
	//Save our input values?
	
	return plistDictionary;
}


@end
