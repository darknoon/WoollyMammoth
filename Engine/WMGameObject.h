//
//  WMGameObject.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

//TODO: copying
//TODO: equality, hash

#import "Matrix.h"

@class WMEngine;
@class WMRenderable;
@class WMLuaScript;

@interface WMGameObject : NSObject {
@protected
	UInt64 objectId;
	
	//Weak
	WMGameObject *parent;
	WMEngine *engine;
		
	//Non-object
	MATRIX transform;
	
	//Strong
	WMRenderable *renderable; //optional
	WMLuaScript *script;
		
	//Modules
	//WMPhysicsBody *body;
	//TODO: sound?
	
	NSMutableArray *mutableChildren;
	//For debugging purposes
	NSString *notes; //optional
}

@property (nonatomic, retain) WMLuaScript *script;
@property (nonatomic, assign) MATRIX transform;
@property (nonatomic, retain) WMRenderable *renderable;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, assign) WMGameObject *parent;
@property (nonatomic, readonly) UInt64 objectId;
@property (nonatomic, readonly) NSArray *children;

- (id)initWithObjectId:(UInt64)inObjectId inEngine:(WMEngine *)inEngine;

- (NSString *)descriptionRecursive;

- (void)update;

- (void)removeFromParent;
- (void)addChild:(WMGameObject *)inChild;
- (void)removeChild:(WMGameObject *)inChild;

@end
