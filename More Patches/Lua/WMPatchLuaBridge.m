//
//  WMPatchLuaBridge.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#include "lua.h"
#include "lauxlib.h"

#import "WMPatchLuaBridge.h"
#import "WMLuaBufferBridge.h"

#import <WMGraph/WMGraph.h>

static const char *WMLuaPatchKey = "com.darknoon.wm.current_patch";

/*

 function setup()
    -- Setup is called once when your program loads
 	-- This is a good place to add any ports your script requires
    -- Port types are number, vec4, index, buffer, 
 	inputPorts.k = {type = "number", default = 0.5, min = 0.1, max = 1.0, name = "k constant"}
 	outputPorts.buf = {type = "buffer", key = "buf"}
 end
 
 function main()
    -- Main is called every time the inputs to your patch change, or once per frame
 	local k = inputPorts.k.value
 
 	local outBuffer = WMBuffer.new(...)
 	outBuffer[1] = {position = vec4(-k, -k, 0, 0)}
    outBuffer[2] = {position = vec4( k, -k, 0, 0)}
    outBuffer[3] = {position = vec4(-k,  k, 0, 0)}
    outBuffer[4] = {position = vec4( k,  k, 0, 0)}
    
	outputPorts.buf.value = outBuffer
 end
 
*/


int WMPatch_lua_addInputPort(lua_State *L);
int WMPatch_lua_addOutputPort(lua_State *L);

int WMPatch_lua_getInputPort(lua_State *L);
int WMPatch_lua_getOutputPort(lua_State *L);

int WMPatch_lua_WMPort_getValue(lua_State *L);
int WMPatch_lua_WMPort_setValue(lua_State *L);


static const luaL_Reg port_metatable[] = {
	{"__index", WMPatch_lua_WMPort_getValue},
	{"__newindex", WMPatch_lua_WMPort_setValue},
	{NULL, NULL}
};

static const luaL_Reg port_inputArray_metatable[] = {
	{"__index", WMPatch_lua_getInputPort},
	{"__newindex", WMPatch_lua_addInputPort},
	{NULL, NULL}
};

static const luaL_Reg port_outputArray_metatable[] = {
	{"__index", WMPatch_lua_getOutputPort},
	{"__newindex", WMPatch_lua_addOutputPort},
	{NULL, NULL}
};

// Read a port name and forget about the inputPorts table on the stack. We just want to get the port.
// -2, +1
int WMPatch_lua_getPort(lua_State *L, BOOL isInput) {
	//1 inputPorts
	//2 key

	//Get the key
	NSString *portKey = [[NSString alloc] initWithCString:lua_tostring(L, 2) encoding:NSUTF8StringEncoding];
	//Remove our arguments
	lua_pop(L, 2);
	
	//Get the patch's port
	lua_getfield(L, LUA_REGISTRYINDEX, WMLuaPatchKey);
	const void *patchPtr = lua_touserdata(L, -1);
	WMPatch *patch = (__bridge WMPatch *)patchPtr;
	lua_pop(L, 1);
	
	WMPort *port = isInput ? [patch inputPortWithKey:portKey] : [patch outputPortWithKey:portKey];
	
	//Create a userdata with a pointer to the port value
	//WARNING: We assume the port isn't going to go away during the lifetime of the script...
	void *portPtrUserData = lua_newuserdata(L, sizeof(const void *));
	*(const void **)portPtrUserData = (__bridge const void *)port;
	
	//Get the metatable to set on the return value
	lua_getfield(L, LUA_REGISTRYINDEX, "WMPatch.PortObject");
	//Set it
	lua_setmetatable(L, -2);
		
	//We return this port wrapper
	
	return 1;
}

int WMPatch_lua_getInputPort(lua_State *L) {
	return WMPatch_lua_getPort(L, YES);
}

int WMPatch_lua_getOutputPort(lua_State *L) {
	return WMPatch_lua_getPort(L, NO);
}

int WMPatch_lua_addPort(lua_State *L, BOOL isInput) {
	//1 inputPorts ignore
	//2 key
	//3 port definition. parse
	
	NSString *portKey = [[NSString alloc] initWithCString:lua_tostring(L, 2) encoding:NSUTF8StringEncoding];
	
	
	//Get the patch
	lua_getfield(L, LUA_REGISTRYINDEX, WMLuaPatchKey);
	const void *patchPtr = lua_touserdata(L, -1);
	WMPatch *patch = (__bridge WMPatch *)patchPtr;
	lua_pop(L, 1);

	//Remove any existing port
	if (isInput) {
		[patch removeInputPort:[patch inputPortWithKey:portKey]];
	} else {
		[patch removeInputPort:[patch inputPortWithKey:portKey]];		
	}
	
	if (lua_istable(L, 3)) {
		
		//Get the type from the definition
		lua_pushstring(L, "type");
		lua_gettable(L, 3);
		
		if (lua_isstring(L, -1)) {
			
			NSString *type = [[NSString alloc] initWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding];
			lua_pop(L, 3);
			
			WMPort *port = nil;
			if ([type isEqualToString:@"number"]) {
				port = [WMNumberPort portWithKey:portKey];
				//TODO: read default value
				//((WMNumberPort *)port).value = ;
			} else if ([type isEqualToString:@"vec4"]) {
				port = [WMVector4Port portWithKey:portKey];
			} else if ([type isEqualToString:@"buffer"]) {
				port = [WMBufferPort portWithKey:portKey];
			}
			
			isInput ? [patch addInputPort:port] : [patch addOutputPort:port];
			
			return 0;
		} else {
			//Return error: need a type parameter in the table		
			lua_pop(L, 3);
			lua_pushstring(L, "missing type parameter for port");
			lua_error(L);
			return 1;
		}
	} else {
		//Not a table
		lua_pop(L, 3);
		lua_pushstring(L, "to create a port pass in a table like {type = \"number\", default = 0.5, min = 0.1, max = 1.0}");
		lua_error(L);
		return 1;
	}
}


int WMPatch_lua_addInputPort(lua_State *L) {
	return WMPatch_lua_addPort(L, YES);
}

int WMPatch_lua_addOutputPort(lua_State *L) {
	return WMPatch_lua_addPort(L, NO);
}


// Return the current value, converted to a lua type for the given port
// -2, +1
int WMPatch_lua_WMPort_getValue(lua_State *L) {
	//1 = pointer-filled userdata representing the port
	//2 = must be "value" currently
	
	const void *portPtr = *(const void **)lua_touserdata(L, 1);
	WMPort *port = (__bridge WMPort *)portPtr;
	
	lua_pop(L, 2);
	
	if ([port isKindOfClass:[WMNumberPort class]]) {
		//Push its value
		float v = ((WMNumberPort *)port).value;
		lua_pushnumber(L, v);
		return 1;
	} else if ([port isKindOfClass:[WMIndexPort class]]) {
		int idx = ((WMIndexPort *)port).index;
		lua_pushinteger(L, idx);
		return 1;
	} else if ([port isKindOfClass:[WMVector4Port class]]) {
		//TODO: implement this port type
		return 0;
	} else if ([port isKindOfClass:[WMBufferPort class]]) {
		WMStructuredBuffer *buffer = ((WMBufferPort *)port).object;
		return WMLuaBufferBridge_pushBuffer(L, buffer);
	} else {
		//Can't handle this type
		return 0;
	}
}

// -3, +0
int WMPatch_lua_WMPort_setValue(lua_State *L) {
	//1 = pointer-filled userdata representing the port
	//2 = must be "value" currently
	//3 = the new value
	
	const void *portPtr = *(const void **)lua_touserdata(L, 1);
	WMPort *port = (__bridge WMPort *)portPtr;

	if ([port isKindOfClass:[WMNumberPort class]]) {
		if (lua_isnumber(L, 3)) {
			float v = lua_tonumber(L, 3);
			((WMNumberPort *)port).value = v;			
		}
	} else if ([port isKindOfClass:[WMIndexPort class]]) {
		if (lua_isnumber(L, 3)) {
			int idx = lua_tointeger(L, 3);
			((WMIndexPort *)port).index = idx;
		}
	} else if ([port isKindOfClass:[WMVector4Port class]]) {
		//TODO: implement this port type
	} else if ([port isKindOfClass:[WMBufferPort class]]) {
		//Check if it has the correct metatable for a buffer and get the buffer
		WMStructuredBuffer *buffer = WMLuaBufferBridge_toBuffer(L, 3);
		((WMBufferPort *)port).object = buffer;
	}

	lua_pop(L, 3);
	
	return 0;
	
}


int WMPatch_luaBridge_register(lua_State *L, WMLua *patch) {
	//Register these as global fns, which read from the registry the current patch
	//We can do this as there is currently a lua state per WMLua patch, but this is an implementation detail not exposed to the user
		
	const void* ptr = (__bridge const void*)patch;
	lua_pushlightuserdata(L, (void *)ptr);
	lua_setfield(L, LUA_REGISTRYINDEX, WMLuaPatchKey);
	
		
	//Metatable for an input/output port object (inputPorts.key) with getter/setter for value
	luaL_newmetatable(L, "WMPatch.PortObject");
	luaL_openlib(L, NULL, port_metatable, 0);
	lua_pop(L, 1);
	
	//Create a inputPorts table
	lua_createtable(L, 0, 1);
	//Set inputPorts' metatable
	luaL_newmetatable(L, "WMPatch.InputPorts");
	luaL_openlib(L, NULL, port_inputArray_metatable, 0);
	lua_setmetatable(L, -2);
	lua_setglobal(L, "inputPorts");
	
	//Output ports array metatable (outputPorts)
	luaL_newmetatable(L, "WMPatch.OutputPorts");
	luaL_openlib(L, NULL, port_outputArray_metatable, 0);
	lua_setmetatable(L, -2);
	lua_setglobal(L, "outputPorts");


	
	
	
	return 0;
}


