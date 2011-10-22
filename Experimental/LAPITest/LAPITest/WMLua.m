//
//  WMLua.m
//  LAPITest
//
//  Created by Andrew Pouliot on 9/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMLua.h"

#import "WMLuaScriptingContext.h"

#import "DNTimingMacros.h"

@implementation WMLua {
	WMLuaScriptingContext *context;
}

@synthesize programText;

- (id)init;
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}


- (void)setProgramText:(NSString *)inProgramText;
{
	if (programText != inProgramText && ![programText isEqualToString:inProgramText]) {
		programText = inProgramText;
		
		context = inProgramText ? [[WMLuaScriptingContext alloc] init] : nil;
		
		[context importBuiltinScript:@"WMAPIBuffer"];
		[context importBuiltinScript:@"WMAPI"];
		
		[context doScript:inProgramText];
		
		[context callGlobalFunction:@"setup"];
	}
}

- (void)run;
{
	DNTimerDefine(luaTimer);
	
	DNTimerStart(luaTimer);
	[context callGlobalFunction:@"main"];
	DNTimerEnd(luaTimer);
	
	NSLog(@"Lua: %@", DNTimerGetStringMS(luaTimer));

	[context collectGarbage];	
}

@end
