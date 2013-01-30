//
//  EAGLContext+Extensions.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 4/5/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "EAGLContext+Extensions.h"

#import "WMRenderCommon.h"

NSString *WMEAGLContextCachedExtensionsKey = @"WM.extensions";

@implementation WMEAGLContext (Extensions)

- (NSSet *)supportedExtensions;
{
	NSSet *supportedExtensions = [self cachedObjectForKey:WMEAGLContextCachedExtensionsKey];
	if (!supportedExtensions) {
		NSString *extensionString = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)];
		NSArray *extensions = [extensionString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		supportedExtensions = [NSSet setWithArray:extensions];
		[self cachedObjectForKey:WMEAGLContextCachedExtensionsKey];
	}
	return supportedExtensions;
}

- (BOOL)supportsExtension:(NSString *)inExtension;
{
	return [[self supportedExtensions] containsObject:inExtension];
}

@end
