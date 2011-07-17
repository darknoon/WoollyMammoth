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


@interface WMTweetPhotoStream : WMPatch {
    WMImagePort *outputImage;
//    WMStringPort *outputText;
    WMNumberPort *inputSpeed; // 0.1
    WMTexture2D *lastTexture;
    PhotoTweet *photoTweet;
    double lastTimeChanged;
}

@property (nonatomic, retain) PhotoTweet *photoTweet;
@property (nonatomic, retain) WMTexture2D *lastTexture;
@end
