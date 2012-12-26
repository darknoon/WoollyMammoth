//
//  WMBundleDocument.m
//  WMEdit
//
//  Created by Andrew Pouliot on 12/25/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMBundleDocument.h"

@implementation WMBundleDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError;
{
	if ([contents isKindOfClass:NSFileWrapper.class]) {
		WMComposition *composition = [[WMComposition alloc] initWithFileWrapper:contents error:outError];
		if (composition) {
			_composition = composition;
			return YES;
		}
	}
	return NO;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError;
{
	return [_composition fileWrapperRepresentationWithError:outError];
}

@end
