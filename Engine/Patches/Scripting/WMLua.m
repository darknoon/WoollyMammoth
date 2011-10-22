//
//  WMLua.m
//  LAPITest
//
//  Created by Andrew Pouliot on 9/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMLua.h"

#import "WMLuaScriptingContext.h"
#import "WMPatchLuaBridge.h"

#import "DNTimingMacros.h"

NSString *WMLuaProgramTextKey = @"text";

@interface WMLua ()
@property (nonatomic, copy) NSString *consoleOutput;
@end

@implementation WMLua {
	WMLuaScriptingContext *luaContext;
	NSMutableString *consoleOutputMutable;
}

@synthesize programText;
@synthesize consoleOutput;

+ (NSString *)category;
{
    return WMPatchCategoryUtil;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (id)plistState;
{
	NSMutableDictionary *d = [[super plistState] mutableCopy];
	
	if (self.programText) [d setObject:self.programText forKey:WMLuaProgramTextKey];
	
	return d;
}

- (BOOL)setPlistState:(id)inPlist;
{
	//Load saved shaders
	self.programText = [inPlist objectForKey:WMLuaProgramTextKey];
	
	return [super setPlistState:inPlist];
}

- (void)setProgramText:(NSString *)inProgramText;
{
	if (programText != inProgramText && ![programText isEqualToString:inProgramText]) {
		programText = inProgramText;
		
		consoleOutputMutable = [[NSMutableString alloc] init];
		
		luaContext = inProgramText ? [[WMLuaScriptingContext alloc] init] : nil;
		luaContext.delegate = (id<WMLuaScriptingContextDelegate>)self;
		
		WMPatch_luaBridge_register(luaContext.lua, self);
		
		[luaContext importBuiltinScript:@"WMAPIBuffer"];
		[luaContext importBuiltinScript:@"WMAPI"];
		
		[luaContext doScript:inProgramText];
		
		[luaContext callGlobalFunction:@"setup"];
	}
}

- (void)luaContext:(WMLuaScriptingContext *)context didOutputStringToConsole:(NSString *)inString;
{
	ZAssert(context == luaContext, @"Recieved console output from the wrong context!");
	[consoleOutputMutable appendFormat:@"-> %@\n", inString];
	self.consoleOutput = consoleOutputMutable;
}

- (void)luaContext:(WMLuaScriptingContext *)context didEncounterError:(NSError *)inError;
{
	[consoleOutputMutable appendFormat:@"ERROR: %@", [inError localizedDescription]];
	self.consoleOutput = consoleOutputMutable;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary*)args;
{
	if (luaContext) {
		//Clear context
		consoleOutputMutable = [[NSMutableString alloc] init];
		
		DNTimerDefine(luaTimer);
		
		DNTimerStart(luaTimer);
		[luaContext callGlobalFunction:@"main"];
		DNTimerEnd(luaTimer);
		
		//NSLog(@"Lua: %@", DNTimerGetStringMS(luaTimer));
		
		//This is triggering segfaults. Find out why!
		//[luaContext collectGarbage];
		
		self.consoleOutput = consoleOutputMutable;
	}
	
	//TODO: error return on compile error
	return YES;
}

@end
