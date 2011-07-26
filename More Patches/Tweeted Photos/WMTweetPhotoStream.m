//
//  WMTweetPhotoStream.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMTweetPhotoStream.h"

#import "WMTexture2D.h"
#import "TweetServerCommunicator.h"
#import "PhotoTweet.h"


@implementation WMTweetPhotoStream
@synthesize photoTweet, lastTexture, timer = _timer, communicator;

+ (NSString *)humanReadableTitle {
    return @"Tweeted Photos";
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass(self)]];
	[pool drain];
}


/* clamp 0 - 1 and return a decent time in seconds */

- (double)timeForSpeed {
    double clampedSpeed = inputSpeed.value;
    if (clampedSpeed == 0.0) clampedSpeed = 0.3;
    return 10 * clampedSpeed; // 0 - 10 seconds
}


+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputSpeed"]) {
		return [NSNumber numberWithFloat:0.3f];
	}
	return nil;
}

- (id)init {
    self = [super init];
    
    
    return self;
}

- (void)nextOne:(NSTimer *)t {
    _getNextOne = YES;
}


- (BOOL)setup:(WMEAGLContext *)context {
    self.communicator = [[TweetServerCommunicator alloc] init];  // this fires up the search engine and downloading photos
    // we need a string input!
    communicator.searchToken = @"iosdevcamp";

    _timer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(nextOne:) userInfo:nil repeats:YES] retain];
    return YES;
    
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
//    double secondsUntilNextPull = [self timeForSpeed];
    
    if (_getNextOne) [communicator advanceToNextTweet];

    PhotoTweet *tweet = [communicator currentTweet];
    
    if (tweet != photoTweet) {
        self.photoTweet = tweet;
        self.lastTexture = nil;
    }
    if (!self.photoTweet) return NO;
    
    if (!self.lastTexture) {
        UIImage *photoImage = [self.photoTweet photoImage];
        if (!photoImage) photoImage = [UIImage imageNamed:@"eli"];
        

        
        self.lastTexture = [[WMTexture2D alloc] initWithImage:photoImage];
        lastTimeChanged = time;
    }
    
    if (!self.lastTexture) return NO;
        
    _getNextOne = NO;

    outputImage.image = self.lastTexture;
    return YES;
}

- (void)cleanup:(WMEAGLContext *)context {
    [communicator release];
    communicator = nil;
    [photoTweet release];
    photoTweet = nil;
    [lastTexture release];
    lastTexture = nil;
    [_timer invalidate];
    [_timer release];
    
}

@end
