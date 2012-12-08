//
//  EAGLContext+Extensions.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 4/5/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "EAGLContext+Extensions.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NSString *WMEAGLContextCachedExtensionsKey = @"WM.extensions";

@implementation WMEAGLContext (EAGLContext_Extensions)

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
