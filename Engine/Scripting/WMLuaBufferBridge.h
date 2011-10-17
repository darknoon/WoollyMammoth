//
//  WMLuaBufferBridge.h
//  LAPITest
//
//  Created by Andrew Pouliot on 9/29/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "lua.h"
#import "lualib.h"

@class WMStructuredBuffer;

extern int WMLuaBufferBridge_register(lua_State *L);

//Returns whether the given object is a lua object representing a buffer.
//-0, +0
extern BOOL WMLuaBufferBridge_isBuffer(lua_State *L, int idx);

// -0, +0
extern WMStructuredBuffer *WMLuaBufferBridge_toBuffer(lua_State *L, int idx);

// -0, +1
extern int WMLuaBufferBridge_pushBuffer(lua_State *L, WMStructuredBuffer *buffer);