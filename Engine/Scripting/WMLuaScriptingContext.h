//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

@class WMGameObject;

@class WMLuaScriptingContext;

@protocol WMLuaScriptingContextDelegate <NSObject>
- (void)luaContext:(WMLuaScriptingContext *)context didOutputStringToConsole:(NSString *)inString;
- (void)luaContext:(WMLuaScriptingContext *)context didEncounterError:(NSError *)inString;
@end

@interface WMLuaScriptingContext : NSObject

@property (weak, nonatomic) id<WMLuaScriptingContextDelegate> delegate;

//TODO: make this not necessary. Currently used by the patch bridge.
@property (nonatomic) lua_State *lua;

- (void)doScript:(NSString *)inScript;
- (void)importBuiltinScript:(NSString *)resourceName;
- (void)callGlobalFunction:(NSString *)inFunctionName;

- (void)collectGarbage;

@end


extern NSString *WMLuaScriptingContextErrorDomain;

enum {
	//Run-time error
	WMLuaScriptingContextErrorRuntime = LUA_ERRRUN,
	//Syntax error
	WMLuaScriptingContextErrorSyntax = LUA_ERRSYNTAX,
	//Could not allocate memory error
	WMLuaScriptingContextErrorMemory = LUA_ERRMEM,
	//Error handling an error
	WMLuaScriptingContextErrorError = LUA_ERRERR,
};