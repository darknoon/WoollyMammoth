//
//  WMAccelerometer.mm
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/4/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMAccelerometer.h"


@implementation WMAccelerometer

+ (WMAccelerometer *)sharedAccelerometer;
{
	static WMAccelerometer *sharedAccelerometer;
	if (!sharedAccelerometer) {
		sharedAccelerometer = [[WMAccelerometer alloc] init];
	}
	return sharedAccelerometer;
}

- (id) init {
	[super init];
	if (self == nil) return self; 
	
	lowPassFactor = 0.95f;
	
	motionManager = [[CMMotionManager alloc] init];
	
	
	//TODO: handle non-iPhone 4 case
	if ([motionManager isDeviceMotionAvailable]) {
		[motionManager startDeviceMotionUpdates];
		gyroAvailable = YES;
	} else {
		[motionManager startAccelerometerUpdates];
		gyroAvailable = NO;
	}
	
	gravity = (GLKVector3){0.0f, 0.5f, 0.5f};
	
	//Device is being held straight up-down unless we hear otherwise
	
	return self;
}

- (GLKVector3)gravity;
{
#if TARGET_IPHONE_SIMULATOR
	return GLKVector3Make(0.0f, -10.0f, 0.0f);
#endif
	if (gyroAvailable) {
		CMDeviceMotion *motion = [motionManager deviceMotion];
		if (motion) {
			CMAcceleration grav = [motion gravity];
			return GLKVector3Make(grav.x, grav.y, grav.z);
		} else {
			return GLKVector3Make(0.0f, 0.0f, 0.0f);
		}
	} else {
		const float lowPassRatio = 0.1f;
		CMAcceleration accel = [motionManager accelerometerData].acceleration;
		acceleration = GLKVector3Make(accel.x, accel.y, accel.z);
		//TODO: add c++ to GLKVector...
		//gravity = lowPassRatio * acceleration + (1.0f - lowPassRatio) * gravity;
		gravity = GLKVector3Add(GLKVector3MultiplyScalar(acceleration, lowPassRatio), GLKVector3MultiplyScalar(gravity, (1.0f - lowPassRatio)));
		return gravity;
	}
}


- (GLKVector3)rotationRate;
{
	if (gyroAvailable) {
		CMDeviceMotion *motion = [motionManager deviceMotion];
		if (motion) {
			CMRotationRate rotationRate = [motion rotationRate];
			return (GLKVector3){rotationRate.x, rotationRate.y, rotationRate.z};
		} else {
			return (GLKVector3){0.0f, 0.0f, 0.0f};
		}
	} else {
		//TODO: return something based on something!
		//This is total bs
		
		float gravityDifference = length(acceleration - gravity);
		return gravityDifference * 10.f * GLKVector3Make(-0.4f, -0.2f, -0.3f);
	}
}


- (void) dealloc;
{
	[motionManager release];
	[super dealloc];
}



@end
