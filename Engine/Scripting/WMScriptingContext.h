//
//  WMScriptingContext.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

@class WMEngine;
@class WMGameObject;

@interface WMScriptingContext : NSObject {
	WMEngine *engine;

	lua_State *lua;
}

- (id)initWithEngine:(WMEngine *)inEngine;

- (void)setObjectToGameObject:(WMGameObject *)inObject;

- (void)doScript:(NSString *)inScript;

@end
