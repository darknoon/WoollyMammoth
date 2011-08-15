//
//  WMAccelerometer.mm
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/4/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMAccelerometer.h"

#import <CoreMotion/CoreMotion.h>

static int WMAccelerometerDelegateCount;

@implementation WMAccelerometer {
	BOOL gyroAvailable;
	
	//If gyro not available, we have to calculate this ourselves
	//Low pass filter on acceleration
	GLKVector3 gravity;
	//This is used to do a low pass to separate gravity and user acceleration
	GLKVector3 acceleration;
	
	GLKVector3 rotationRate;
	
	float lowPassFactor;
	NSTimeInterval lastLogTime;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass(self)]];
	[pool drain];
}

+ (NSString *)category;
{
	return WMPatchCategoryDevice;
}

+ (WMAccelerometer *)sharedAccelerometer;
{
	static WMAccelerometer *sharedAccelerometer;
	if (!sharedAccelerometer) {
		sharedAccelerometer = [[WMAccelerometer alloc] init];
	}
	return sharedAccelerometer;
}

//This queue synchronizes acces to the shared CMMotionManager
+ (NSOperationQueue *)motionUpdateQueue;
{
	return [NSOperationQueue mainQueue];
}

+ (CMMotionManager *)sharedMotionManager;
{
	static CMMotionManager *sharedMotionManager = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMotionManager = [[CMMotionManager alloc] init];		
	});
	
	return sharedMotionManager;
}


+ (void)incrementDelegateCount;
{
	[[self motionUpdateQueue] addOperationWithBlock:^(void) {
		WMAccelerometerDelegateCount++;
		
		if (WMAccelerometerDelegateCount == 1) {
			[[self sharedMotionManager] startDeviceMotionUpdates];
		}
	}];
}

+ (void)decrementDelegateCount;
{
	[[self motionUpdateQueue] addOperationWithBlock:^(void) {
		WMAccelerometerDelegateCount--;
		if (WMAccelerometerDelegateCount == 0) {
			[[self sharedMotionManager] stopDeviceMotionUpdates];
		}
	}];	
}

- (id) init {
	self = [super init];
	if (self == nil) return self; 
	
	lowPassFactor = 0.95f;
		
	gravity = (GLKVector3){0.0f, 0.5f, 0.5f};
	
	//Device is being held straight up-down unless we hear otherwise
	
	return self;
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	gyroAvailable = [[[self class] sharedMotionManager] isDeviceMotionAvailable];
	[[self class] incrementDelegateCount];
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	[[self class] decrementDelegateCount];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
#if TARGET_IPHONE_SIMULATOR
	gravity = GLKVector3Make(0.0f, -10.0f, 0.0f);
#endif
	
	if (gyroAvailable) {
		CMDeviceMotion *motion = [[WMAccelerometer sharedMotionManager] deviceMotion];
		if (motion) {
			CMAcceleration grav = [motion gravity];
			gravity = (GLKVector3){grav.x, grav.y, grav.z};

			CMAcceleration accel = [motion userAcceleration];
			acceleration = (GLKVector3){accel.x, accel.y, accel.z};

			CMRotationRate cmRotationRate = [motion rotationRate];
			rotationRate = (GLKVector3){cmRotationRate.x, cmRotationRate.y, cmRotationRate.z};
		} else {
			gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
		}
	} else {
		const float lowPassRatio = 0.1f;
		CMAcceleration accel = [[WMAccelerometer sharedMotionManager] accelerometerData].acceleration;
		acceleration = (GLKVector3){accel.x, accel.y, accel.z};
		gravity = lowPassRatio * acceleration + (1.0f - lowPassRatio) * gravity;
		
		//TODO: return something based on something!
		//This is total bs
		
		float gravityDifference = length(acceleration - gravity);
		rotationRate = gravityDifference * 10.f * GLKVector3Make(-0.4f, -0.2f, -0.3f);
	}
	
	//Write to output ports
	
	outputAcceleration.v = acceleration;
	outputGravity.v = gravity;
	outputRotationRate.v = rotationRate;
	
	return YES;
}


- (void) dealloc;
{
	[super dealloc];
}



@end
