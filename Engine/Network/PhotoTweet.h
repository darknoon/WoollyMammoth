//
//  PhotoTweet.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PhotoTweet : NSObject
@property (nonatomic, retain) NSMutableDictionary *tweet;
@property (nonatomic, retain) UIImage *image;


+ (PhotoTweet *)photoTweetWithDictionary:(NSMutableDictionary *)d;
- (PhotoTweet *)initWithDictionary:(NSMutableDictionary *)d;

- (NSString *)photoImageMediumURLString;
- (NSString *)cleanText; // stripped of tags, urls, and maybe with user name prepended
- (BOOL)imageLoaded;
- (UIImage *)photoImage;

@end

// Keys we expect:
// photoUrl
// cleanText
// screen_name

