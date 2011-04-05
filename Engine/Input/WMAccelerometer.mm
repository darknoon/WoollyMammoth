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
	
	gravity = Vec3(0.0f, 0.5f, 0.5f);
	
	//Device is being held straight up-down unless we hear otherwise
	
	return self;
}

- (Vec3)gravity;
{
#if TARGET_IPHONE_SIMULATOR
	return Vec3(0.0f, -10.0f, 0.0f);
#endif
	if (gyroAvailable) {
		CMDeviceMotion *motion = [motionManager deviceMotion];
		if (motion) {
			CMAcceleration grav = [motion gravity];
			return Vec3(grav.x, grav.y, grav.z);
		} else {
			return Vec3(0.0f, 0.0f, 0.0f);
		}
	} else {
		const float lowPassRatio = 0.1f;
		CMAcceleration accel = [motionManager accelerometerData].acceleration;
		acceleration = Vec3(accel.x, accel.y, accel.z);
		gravity = lowPassRatio * acceleration + (1.0f - lowPassRatio) * gravity;
		return gravity;
	}
}


- (Vec3)rotationRate;
{
	if (gyroAvailable) {
		CMDeviceMotion *motion = [motionManager deviceMotion];
		if (motion) {
			CMRotationRate rotationRate = [motion rotationRate];
			return Vec3(rotationRate.x, rotationRate.y, rotationRate.z);
		} else {
			return Vec3(0.0f, 0.0f, 0.0f);
		}
	} else {
		//TODO: return something based on something!
		float gravityDifference = (acceleration - gravity).length();
		return gravityDifference * 10.f * Vec3(-0.4f, -0.2f, -0.3f);
	}

}


- (void) dealloc;
{
	[motionManager release];
	[super dealloc];
}



@end
