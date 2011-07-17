//
//  TweetServerCommunicator.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhotoTweet;

@interface TweetServerCommunicator : NSObject {
    NSMutableArray *_downloadedPhotoTweets;
    NSMutableArray *_allPhotoTweets;
    unsigned long long _lastIDNumber;
    NSTimer *_timer;
    NSOperationQueue *queue;
}

@property (nonatomic, retain) NSOperationQueue *queue;

+ (TweetServerCommunicator *)commmunicator;

- (PhotoTweet *)currentTweet;
- (void)photoTweetGotImage:(PhotoTweet *)photoTweet;
- (void)photoTweetFailedToGetImage:(PhotoTweet *)photoTweet;
- (void)advanceToNextTweet;

@end
