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

@implementation EAGLContext (EAGLContext_Extensions)

- (NSSet *)supportedExtensions;
{
	NSString *extensionString = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)];
    NSArray *extensions = [extensionString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	return [NSSet setWithArray:extensions];
}

- (BOOL)supportsExtension:(NSString *)inExtension;
{
	return [[self supportedExtensions] containsObject:inExtension];
}

@end
