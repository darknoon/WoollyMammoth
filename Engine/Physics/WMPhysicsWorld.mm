//
//  WMPhysicsWorld.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMPhysicsWorld.h"


@implementation WMPhysicsWorld

- (id) init {
	self = [super init];
	if (self == nil) return self; 
	
	btCollisionConfiguration* sCollisionConfig = new btDefaultCollisionConfiguration();
	
	btBroadphaseInterface* sBroadphase = new btDbvtBroadphase();
	
	btCollisionDispatcher* sCollisionDispatcher = new btCollisionDispatcher(sCollisionConfig);
	btSequentialImpulseConstraintSolver* sConstraintSolver = new btSequentialImpulseConstraintSolver;
		
	world = new btDiscreteDynamicsWorld(sCollisionDispatcher,sBroadphase,sConstraintSolver,sCollisionConfig);
	world->setGravity(btVector3(0,-10,0));
	
	return self;
}

- (void) dealloc
{
	delete world;
	
	[super dealloc];
}


@end
