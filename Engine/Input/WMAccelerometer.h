//
//  WMAccelerometer.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/4/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Vector.h"
#import "Matrix.h"

#import <CoreMotion/CoreMotion.h>

@interface WMAccelerometer : NSObject {

	BOOL gyroAvailable;
	
	//If gyro not available, we have to calculate this ourselves
	//Low pass filter on acceleration
	Vec3 gravity;
	Vec3 acceleration;

	float lowPassFactor;
	NSTimeInterval lastLogTime;
	CMMotionManager *motionManager;
}

//TODO: remove this. Instead, provide instances that can have their own low pass factors that get events from a class-level object.
//This should keep to the design goal that there should be separate WM instances loaded at once (no globals/singletons)
+ (WMAccelerometer *)sharedAccelerometer;

//Low pass filtered (~ gravity)
@property (readonly) Vec3 gravity;
//TTT ork!
@property (readonly) Vec3 rotationRate;

@end
