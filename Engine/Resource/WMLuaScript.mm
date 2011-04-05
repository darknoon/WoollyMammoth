//
//  WMLuaScript.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/30/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMLuaScript.h"
#import "WMScriptingContext.h"

@implementation WMLuaScript

- (BOOL)loadWithBundle:(NSBundle *)inBundle inScriptingContext:(WMScriptingContext *)inScriptingContext error:(NSError **)outError;
{
	if (!isLoaded) {
		
		NSString *filePath = [resourceName stringByAppendingPathExtension:@"lua"];
		[self requireAssetFileSynchronous:filePath];
		
		scriptText = [[NSString stringWithContentsOfFile:[[inBundle bundlePath] stringByAppendingPathComponent:filePath] encoding:NSUTF8StringEncoding error:outError] retain];
		
		[inScriptingContext doScript:scriptText];
		
		isLoaded = scriptText != nil;
	}
	return isLoaded;
}

- (void)executeInScriptingContext:(WMScriptingContext *)inScriptingContext thisObject:(WMGameObject *)inThisObject;
{
	[inScriptingContext setObjectToGameObject:inThisObject];
	[inScriptingContext doScript:[resourceName stringByAppendingString:@".update()"]];
}

- (void) dealloc
{	
	[super dealloc];
}


@end
