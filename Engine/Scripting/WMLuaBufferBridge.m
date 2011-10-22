//
//  WMLuaBufferBridge.m
//  LAPITest
//
//  Created by Andrew Pouliot on 9/29/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMLuaBufferBridge.h"

#import "lauxlib.h"
#import "WMStructuredBuffer.h"

NSString *const WMStructuredBufferLibraryLuaName = @"WMBuffer";

const char *WMLuaBufferBridgeBufferMetatable = "com.darknoon.WMBuffer";
const char *WMLuaBufferBridgeBufferInstanceMetatable = "com.darknoon.WMBuffer.instance";


const char *WMLuaBufferBridgeVectorInstanceMetatable = "com.darknoon.WMVector";

// A buffer is a userdata containing a pointer to the actual buffer. The metatable has a reference to the structure_buffer_release function for the __gc entry

/*
 
 static int newarray (lua_State *L) {
 int n = luaL_checkint(L, 1);
 size_t nbytes = sizeof(NumArray) + (n - 1)*sizeof(double);
 NumArray *a = (NumArray *)lua_newuserdata(L, nbytes);
 
 luaL_getmetatable(L, "LuaBook.array");
 lua_setmetatable(L, -2);
 
 a->size = n;
 return 1;  // new userdatum is already on the stack
}

 */

void luaWM_stackDump (lua_State *L);
void luaWM_stackDump (lua_State *L) {
	int i;
	int top = lua_gettop(L);
	for (i = 1; i <= top; i++) {  /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
				
			case LUA_TSTRING:  /* strings */
				printf("`%s'", lua_tostring(L, i));
				break;
				
			case LUA_TBOOLEAN:  /* booleans */
				printf(lua_toboolean(L, i) ? "true" : "false");
				break;
				
			case LUA_TNUMBER:  /* numbers */
				printf("%g", lua_tonumber(L, i));
				break;
				
			default:  /* other values */
				printf("%s", lua_typename(L, t));
				break;
				
        }
        printf("  ");  /* put a separator */
	}
	printf("\n");  /* end the listing */
}


//Reads the structure off of the stack, writes a userdata representing the buffer
// -1, +1
static int WMLuaBufferBridge_createBuffer(lua_State *L) {
	//Check that we recieved a table
	if (lua_type(L, 1) == LUA_TTABLE) {
		//Look at the entries of the table
		//{name="position", type:WMBuffer.Type.Float, count=4}
		
		//structure.totalSize
		lua_pushstring(L, "totalSize");
		lua_gettable(L, 1);
		lua_Integer totalSize = luaL_checkint(L, -1);
		if (totalSize <= 0 || totalSize > 1024) {
			lua_pushfstring(L, "invalid structure size %d", totalSize);
			lua_error(L);
			return 0;
		}
		//Pop the totalSize
		lua_pop(L, 1);
		
		//structure.fields
		lua_pushstring(L, "fields");
		lua_gettable(L, -2);
		
		//TODO: for loop here. Currently just read the first index
		//fields[1] the 1st index!
		lua_pushnumber(L, 1);
		lua_gettable(L, -2);
		
		WMStructureField field = {};
		
		lua_pushstring(L, "name");
		lua_gettable(L, -2);
		//Make sure the .name is a string 
		luaL_checkstring(L, -1);
		//Get the name string
		size_t nameLength;
		const char* name = lua_tolstring(L, -1, &nameLength);
		memcpy((void *)field.name, name, MIN(nameLength, 255));
		//Pop the name
		lua_pop(L, 1);
		
		lua_pushstring(L, "type");
		lua_gettable(L, -2);
		//Make sure we got a number
		lua_Integer typeInt = luaL_checkint(L, -1);
		//Make sure the number is a valid field type
		switch (typeInt) {
			case WMStructureTypeByte:
			case WMStructureTypeUnsignedByte:
			case WMStructureTypeInt:
			case WMStructureTypeUnsignedInt:
			case WMStructureTypeShort:
			case WMStructureTypeUnsignedShort:
			case WMStructureTypeFloat:
				field.type = typeInt;
				break;				
			default:
				lua_pushfstring(L, "Invalid type %d", typeInt);
				lua_error(L);
				return 0;
		}
		//Pop the type
		lua_pop(L, 1);
		
		lua_pushstring(L, "count");
		lua_gettable(L, -2);
		//Make sure we got a number
		lua_Integer count = luaL_checkint(L, -1);
		if (count > 0) {
			field.count = count;
		} else {
			lua_pushfstring(L, "Count %d is invalid. Count must be > 0", count);
			lua_error(L);
			return 0;
		}
		//Pop the count
		lua_pop(L, 1);
		
		//Pop the fields[0] table, the fields table, and the structure
		lua_pop(L, 3);
		
		WMStructureDefinition *structure = [[WMStructureDefinition alloc] initWithFields:&field count:1 totalSize:totalSize];
		
		WMStructuredBuffer *buffer = [[WMStructuredBuffer alloc] initWithDefinition:structure];
		
		//Transfer ownership of the buffer to the Lua garbage collector
		const void *bufferUserData = (__bridge_retained const void *)buffer;
		
		const void** userData = (const void**)lua_newuserdata(L, sizeof(const WMStructuredBuffer *));
		*userData = bufferUserData;
		
		//Put the metatable for WMBuffer from the registry on the stack and set it on the userdata
		luaL_getmetatable(L, WMLuaBufferBridgeBufferInstanceMetatable);
		lua_setmetatable(L, -2);
		
		return 1;
	} else {
		//Didn't recieve a table!
		return 0;
	}
}

//Reads the buffer and the index off the stack, writes a table of tables
// -1, +1
static int WMLuaBufferBridge_getBufferEntry(lua_State *L) {
	luaL_checkudata(L, 1, WMLuaBufferBridgeBufferInstanceMetatable);
	return 0;
}

//Reads the buffer off the stack, writes a table of tables
// -1, +1
static int WMLuaBufferBridge_getBufferCount(lua_State *L) {
	//Additional safety if someone tries to call the method without the self parameter
	luaL_checkudata(L, 1, WMLuaBufferBridgeBufferInstanceMetatable);
	
	const void **bufferPointer = (const void **)lua_topointer(L, 1);
	WMStructuredBuffer *buffer = (__bridge WMStructuredBuffer *)(*bufferPointer);

	lua_pop(L, 1);
	
	//Push result
	lua_pushinteger(L, buffer.count);
	
	return 1;
}


// Read buffer, index, table from stack
// buffer[1] = {.position = {0, 1, 2, 3}}
// -3, +0
static int WMLuaBufferBridge_setBufferEntry (lua_State *L) {
	//luaL_checkudata(L, 1, WMLuaBufferBridgeBufferInstanceMetatable);

	const void **bufferPointer = (const void **)lua_topointer(L, 1);
	__unsafe_unretained WMStructuredBuffer *buffer = (__bridge WMStructuredBuffer *)(*bufferPointer);
	WMStructureDefinition *structure = buffer.definition;
	
	//TODO: eliminate the need to malloc here
	
	int idx = luaL_checkint(L, 2);
	if (idx > 0) {
		size_t structSize = buffer.definition.size;
		buffer.count = MAX(buffer.count, idx);
		void *data = [buffer dataPointer] + (idx - 1) * structSize;
		if (data) {
			//Iterate over the input table, copying into the data buffer
			
			lua_pushnil(L);
			while (lua_next(L, -2) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */
				//TODO: add more type-safety here!
				
//				printf("%s - %s\n",
//					   lua_typename(L, lua_type(L, -2)),
//					   lua_typename(L, lua_type(L, -1)));
				/* removes 'value'; keeps 'key' for next iteration */
				luaL_checkstring(L, -2);
				WMStructureField field = {};
				if ([structure getFieldNamedUTF8:lua_tostring(L, -2) outField:&field]) { //If this field exists in the structure
					//Get the input array as vec4
					//Assume light userdata with metatable..
					float *vec4Ptr = lua_touserdata(L, -1);
					
					//Iterate over the passed-in table until we have filled in our array for this field or we hit the field's count					
					void *basePtr = data + field.offset;
					
					for (int i=0; i < MIN(field.count, 4); i++) {
						float value = vec4Ptr[i];
						switch (field.type) {
							case WMStructureTypeByte:
								*(char *)(basePtr + sizeof(char) * i) = value;
								break;
							case WMStructureTypeUnsignedByte:
								*(unsigned char *)(basePtr + sizeof(unsigned char) * i) = value;
								break;
							case WMStructureTypeFloat:
								*(float *)(basePtr + sizeof(float) * i) = value;
								break;
								
							default:
#warning fixme
								NSLog(@"UNSUPPORTED!");
								break;
						}
						
					}
					[buffer markRangeDirty:(NSRange){.location = idx, .length = 1}];
				} else {
					NSString *fieldName = [[NSString alloc] initWithUTF8String:lua_tostring(L, -2)];
					NSLog(@"Lua bridge: Attempt to set field not in structure: %@", fieldName);
				}
				lua_pop(L, 1);
			}

		} else {
			lua_pushstring(L, "Out of memmory");
			lua_error(L);
			return 0;
		}
		
	} else {
		lua_pushfstring(L, "Index %d is invalid. Index must be >= 1", idx);
		lua_error(L);
		return 0;
	}
	return 0;
}

// Reads buffer from the stack and writes the description
// -1, +1
static int WMLuaBufferBridge_description (lua_State *L) {
	luaL_checkudata(L, 1, WMLuaBufferBridgeBufferInstanceMetatable);

	const void **bufferPointer = (const void **)lua_topointer(L, 1);
	__unsafe_unretained WMStructuredBuffer *buffer = (__bridge WMStructuredBuffer *)(*bufferPointer);
	//pop the buffer off
	lua_pop(L, 1);
	//put the string on
	lua_pushstring(L, [[buffer debugDescription] UTF8String]);
	return 1;
}

// -1, +0 
// this is the __gc method
static int WMLuaBufferBridge_releaseBuffer(lua_State *L) {
	//Additional safety if someone tries to call the method without the self parameter
	luaL_checkudata(L, 1, WMLuaBufferBridgeBufferInstanceMetatable);
	
	//Grab the userdata and transfer to our control for release!
	const void **bufferPointer = (const void **)lua_topointer(L, 1);
	WMStructuredBuffer *buffer = (__bridge_transfer WMStructuredBuffer *)(*bufferPointer);
	//TODO: suppress unused warning!
	NSLog(@"freeing buffer: %@", buffer);
	
	*bufferPointer = NULL;
	
	//Pop our parameter
	lua_pop(L, 1);
	
	return 0;
}

// -4, +1
// Creates a vector from the arguments on the stack
static int WMLua_createVector(lua_State *L) {
	const int n_arg = lua_gettop(L);
	const int max_count = 4;
	
	float vec [4] = {};
	for (int i=0; i<max_count; i++) {
		vec[i] = i<n_arg ? lua_tonumber(L, 1+i) : 0.0f;
	}

	lua_pop(L, n_arg);
	
	float *userVec = (float *)lua_newuserdata(L, sizeof(float[max_count]));
	for (int i=0; i<max_count; i++) {
		userVec[i] = vec[i];
	}
	
	luaL_getmetatable(L, WMLuaBufferBridgeVectorInstanceMetatable);
	lua_setmetatable(L, -2);
	
	return 1;
}

// -5, +0
static int WMLua_setVector(lua_State *L) {
	float *userVec = (float *)lua_touserdata(L, 1);
	
	const int n_arg = lua_gettop(L);
	const int max_count = 4;
	
	for (int i=0; i<max_count; i++) {
		//account for 1 index and user vec at position 0
		userVec[i] = i < (n_arg - 1) ? lua_tonumber(L, 1 + 1 + i) : 0.0f;
	}
	lua_pop(L, n_arg);
	
	return 0;
}

BOOL WMLuaBufferBridge_isBuffer(lua_State *L, int idx) {
	if (!lua_isuserdata(L, idx)) return NO;
	
	//Get the metatable and compare to the expected metatable
	int hasMetatable = lua_getmetatable(L, idx);
	if (hasMetatable) {
		luaL_getmetatable(L, WMLuaBufferBridgeBufferInstanceMetatable);
		BOOL equal = lua_equal(L, -2, -1);
		//Pop off both metatables
		lua_pop(L, 2);
		
		return equal;
	} else {
		return NO;
	}
}

WMStructuredBuffer *WMLuaBufferBridge_toBuffer(lua_State *L, int idx) {
	if (WMLuaBufferBridge_isBuffer(L, idx)) {
		const void **bufferPointer = (const void **)lua_topointer(L, idx);
		__unsafe_unretained WMStructuredBuffer *buffer = (__bridge WMStructuredBuffer *)(*bufferPointer);
		return buffer;
	} else {
		return nil;
	}
}

// -0, +1
int WMLuaBufferBridge_pushBuffer(lua_State *L, WMStructuredBuffer *buffer) {
	if (buffer) {
		//Transfer ownership of the buffer to the Lua garbage collector
		const void *bufferUserData = (__bridge_retained const void *)buffer;
		
		const void** userData = (const void**)lua_newuserdata(L, sizeof(const WMStructuredBuffer *));
		*userData = bufferUserData;
		
		//Put the metatable for WMBuffer from the registry on the stack and set it on the userdata
		luaL_getmetatable(L, WMLuaBufferBridgeBufferInstanceMetatable);
		lua_setmetatable(L, -2);
		
		return 1;
	} else {
		return 0;
	}
}

// These get added to WMBuffer
static const luaL_Reg buffer_f[] = {
	{"new", WMLuaBufferBridge_createBuffer},
	{NULL, NULL}
};


// These get added to "instances" of WMBuffer via the metatable's __index method
static const luaL_Reg buffer_m[] = {
	{"__len", WMLuaBufferBridge_getBufferCount},
	{"__index", WMLuaBufferBridge_getBufferEntry},
	{"__newindex", WMLuaBufferBridge_setBufferEntry},
	{"__tostring", WMLuaBufferBridge_description},
	{"__gc", WMLuaBufferBridge_releaseBuffer},
	{NULL, NULL}
};


static const luaL_Reg vec_f[] = {
	{"new", WMLua_createVector},
	{NULL, NULL}
};

static const luaL_Reg vec_m[] = {
	{"set", WMLua_setVector},
	{NULL, NULL}
};


int WMLuaBufferBridge_register(lua_State *L) {
	//Create the metatable that provides the WMBuffer:new() method
	luaL_newmetatable(L, WMLuaBufferBridgeBufferMetatable);
	
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);  //pushes the metatable
	lua_settable(L, -3);   //metatable.__index = metatable
	lua_pop(L, 1);
        
	luaL_openlib(L, "WMBuffer", buffer_f, 0);
	lua_pop(L, 1);
	
	luaL_newmetatable(L, WMLuaBufferBridgeBufferInstanceMetatable);
	luaL_openlib(L, NULL, buffer_m, 0);
	lua_pop(L, 1);
	
	luaL_openlib(L, "WMVec4", vec_f, 0);
	lua_pop(L, 1);

	luaL_newmetatable(L, WMLuaBufferBridgeVectorInstanceMetatable);
	lua_pushvalue(L, -1);  //pushes the metatable
	lua_setfield(L, -1, "__index");
	
	luaL_openlib(L, NULL, vec_m, 0);
	lua_pop(L, 1);

	return 0;
}
