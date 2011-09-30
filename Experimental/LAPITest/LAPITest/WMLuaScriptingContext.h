//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

@class WMGameObject;

@interface WMLuaScriptingContext : NSObject {

	lua_State *lua;
}


- (void)doScript:(NSString *)inScript;
- (void)importBuiltinScript:(NSString *)resourceName;
- (void)callGlobalFunction:(NSString *)inFunctionName;

- (void)collectGarbage;

@end
