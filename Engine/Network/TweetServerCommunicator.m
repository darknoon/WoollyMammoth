//
//  TweetServerCommunicator.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "TweetServerCommunicator.h"
#import "PhotoTweet.h"

@implementation TweetServerCommunicator

- (PhotoTweet *)currentTweet {
    return _downloadedPhotoTweets.count ? [_downloadedPhotoTweets objectAtIndex:0] : nil;
}
                                           
- (void)advanceToNextTweet {
    if (_downloadedPhotoTweets.count > 1) {
        PhotoTweet * last = [_downloadedPhotoTweets lastObject];
        [_downloadedPhotoTweets removeObject:last];
        [_downloadedPhotoTweets insertObject:last atIndex:0];
    }
}

- (void)talkToServer:(NSTimer *)t {
    
}

#define GRAB_MORE_TIME 10.0

- (id)init {
    self = [super init];
    _downloadedPhotoTweets = [[NSMutableArray alloc] init];
    _allPhotoTweets = [[NSMutableArray alloc] init];
    _timer = [[NSTimer scheduledTimerWithTimeInterval:GRAB_MORE_TIME target:self selector:@selector(talkToServer:) userInfo:nil repeats:YES] retain];
    [self talkToServer:nil]; 
    return self;
}

+ (TweetServerCommunicator *)commmunicator {
    static TweetServerCommunicator *_myOneAndOnly;
    if(!_myOneAndOnly) _myOneAndOnly = [[self alloc] init];
    return _myOneAndOnly;
}


@end
