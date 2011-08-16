//
//  WMTweetPhotoStream.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"
#import "PhotoTweet.h"
#import "TweetServerCommunicator.h"

@interface WMTweetPhotoStream : WMPatch {
    WMImagePort *outputImage;
//    WMStringPort *outputText;
    WMNumberPort *inputSpeed; // 0.1
    WMTexture2D *lastTexture;
    PhotoTweet *photoTweet;
    double lastTimeChanged;
    BOOL _getNextOne;
}

@property (nonatomic, strong) PhotoTweet *photoTweet;
@property (nonatomic, strong) WMTexture2D *lastTexture;
@property (nonatomic, strong) TweetServerCommunicator *communicator;
@property (nonatomic, strong) NSTimer *timer;
@end
