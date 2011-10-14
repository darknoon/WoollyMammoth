//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMLuaScriptingContext.h"

#import "WMLuaBufferBridge.h"

NSString *WMLuaScriptingContextErrorDomain = @"com.darknoon.wm.lua";

@interface WMLuaScriptingContext () {	
	lua_State *lua;
}

- (void)printFromScript:(NSString *)inString;
- (void)importBuiltinScript:(NSString *)resourceName;
@end


static int WMScriptingContextPrint(lua_State *lua) {
	//Get a pointer back to our object
	lua_getglobal(lua, "WMScriptingContext");
	int contextPtr = 0;
	lua_number2int(contextPtr, lua_tonumber(lua, -1));
	lua_pop(lua, 1);
	
	//WHEE, ARC
	id self = (__bridge id)((const void*)contextPtr);
	NSMutableString *printString = [[NSMutableString alloc] init];
	
	int n = lua_gettop(lua);  /* number of arguments */
	int i;
	lua_getglobal(lua, "tostring");
	for (i=1; i<=n; i++) {
		const char *s;
		lua_pushvalue(lua, -1);  /* function to be called */
		lua_pushvalue(lua, i);   /* value to print */
		lua_call(lua, 1, 1);
		s = lua_tostring(lua, -1);  /* get result */
		if (s == NULL)
			return luaL_error(lua, LUA_QL("tostring") " must return a string to "
							  LUA_QL("print"));
		[printString appendFormat: i > 1 ? @"\t%s" : @"%s", s];
		lua_pop(lua, 1);  /* pop result */
	}
	[self printFromScript:printString];
	return 0;
}

static int WMScriptingContextErrorHandler(lua_State *lua) {
	if (!lua_isstring(lua, 1))  /* 'message' not a string? */
		return 1;  /* keep it intact */
	lua_getfield(lua, LUA_GLOBALSINDEX, "debug");
	if (!lua_istable(lua, -1)) {
		lua_pop(lua, 1);
		return 1;
	}
	lua_getfield(lua, -1, "traceback");
	if (!lua_isfunction(lua, -1)) {
		lua_pop(lua, 2);
		return 1;
	}
	lua_pushvalue(lua, 1);  /* pass error message */
	lua_pushinteger(lua, 2);  /* skip this function and traceback */
	lua_call(lua, 2, 1);  /* call debug.traceback */
	return 1;
}

@implementation WMLuaScriptingContext

@synthesize delegate;

- (id)init;
{
	self = [super init];
	if (!self) return nil;
		
	lua = lua_open();	
	luaL_openlibs(lua);
	
	//Set up our callback functions
	lua_register(lua, "print", WMScriptingContextPrint);

	//Set ourselves as a global
	//TODO: convert this to use the registry instead!!
	lua_pushnumber(lua, (int)self);
	lua_setglobal(lua, "WMScriptingContext");
	
	WMLuaBufferBridge_register(lua);
	
	return self;
}

- (void)importBuiltinScript:(NSString *)resourceName;
{
	NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"lua"];
	if (!path) {
		NSLog(@"Couldn't import script %@", resourceName);
	} else {
		[self doScript:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL]];
	}
}

- (void) dealloc
{
	lua_close(lua);
	lua = NULL;
}

- (NSString *)errorTypeDescription:(int)inErrType;
{
	switch (inErrType) {
		case LUA_ERRRUN:
			return @"runtime error";
		case LUA_ERRMEM:
			return @"memory error";
		case LUA_ERRSYNTAX:
			return @"syntax error";
		default:
			return @"unknown error";
			break;
	}
}

- (void)callGlobalFunction:(NSString *)inFunctionName;
{
	lua_getglobal(lua, [inFunctionName UTF8String]);
	
	//TODO: check to make sure value on the stack is actually a function!
	if(lua_isfunction(lua, -1)) {
		
		//Call inFunctionName() with no return args
		lua_call(lua, 0, 0);
	}
}

- (void)outputLuaError:(int)status errString:(const char *)errString;
{
	NSString *errorDescription = [NSString stringWithFormat:@"lua %@: %s", [self errorTypeDescription:status], errString];
	DLog(@"%@", errorDescription);
	
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:errorDescription, NSLocalizedDescriptionKey, nil];
	NSError *error = [[NSError alloc] initWithDomain:WMLuaScriptingContextErrorDomain code:status userInfo:userInfo];

	[delegate luaContext:self didEncounterError:error];
}

- (void)doScript:(NSString *)inScript;
{
	//Add error handler to caputure stack BT
	lua_pushcfunction(lua, WMScriptingContextErrorHandler);
	
	//Load in the script to execute
	int status = luaL_loadstring(lua, [inScript UTF8String]);
	if (status != 0) {
		[self outputLuaError:status errString:lua_tostring(lua, -1)];
	}
	
	status = lua_pcall(lua, 0, LUA_MULTRET, -2);
	if (status != 0) {
		[self outputLuaError:status errString:lua_tostring(lua, -1)];
	}
}

- (void)collectGarbage;
{
	lua_gc(lua, LUA_GCCOLLECT, 0);
}

- (void)printFromScript:(NSString *)inString;
{
	[delegate luaContext:self didOutputStringToConsole:inString];
}

@end
