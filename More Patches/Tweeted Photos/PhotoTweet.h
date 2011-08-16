//
//  PhotoTweet.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "TweetServerCommunicator.h"

@interface PhotoTweet : NSObject <ASIHTTPRequestDelegate>
@property (nonatomic, weak) TweetServerCommunicator *communicator;
@property (nonatomic, strong) NSMutableDictionary *tweet;
@property (nonatomic, strong) UIImage *image;


+ (PhotoTweet *)photoTweetWithDictionary:(NSMutableDictionary *)d;
- (PhotoTweet *)initWithDictionary:(NSMutableDictionary *)d;

- (NSString *)photoImageMediumURLString;
- (NSString *)cleanText; // stripped of tags, urls, and maybe with user name prepended
- (UIImage *)photoImage;
- (BOOL)hasImage;
- (unsigned long long)twitterId;
@end

// Keys we expect:
// photoUrl
// cleanText
// screen_name

