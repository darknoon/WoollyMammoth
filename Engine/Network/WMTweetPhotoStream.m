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
@synthesize photoTweet, lastTexture;

- (BOOL)setup:(WMEAGLContext *)context;
{
    [TweetServerCommunicator commmunicator];
    return YES;
}

/* clamp 0 - 1 and return a decent time in seconds */

- (double)timeForSpeed {
    double clampedSpeed = inputSpeed.value;
    return 10 * clampedSpeed; // 0 - 10 seconds
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
    double secondsUntilNextPull = [self timeForSpeed];
    
    if (time - lastTimeChanged > secondsUntilNextPull) {
        [[TweetServerCommunicator commmunicator] advanceToNextTweet];
    }
    
    PhotoTweet *tweet = [[TweetServerCommunicator commmunicator] currentTweet];
    
    if (tweet != photoTweet) {
        self.photoTweet = tweet;
        self.lastTexture = nil;
    }
    if (!self.photoTweet) return NO;
    
    if (!self.lastTexture) {
        UIImage *photoImage = [self.photoTweet photoImage];
        self.lastTexture = [[WMTexture2D alloc] initWithImage:photoImage];
        lastTimeChanged = time;
    }
    
    if (!self.lastTexture) return NO;
        
    outputImage.image = self.lastTexture;
    return YES;
}

- (void)cleanup:(WMEAGLContext *)context {
    
}

@end
