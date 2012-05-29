//
//  WMAudioBuffer.h
//  WMEdit
//
//  Created by Andrew Pouliot on 5/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

@interface WMAudioBuffer : NSObject

- (id)initWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@property (nonatomic, strong, readonly) NSArray *sampleBuffers;

@property (nonatomic, readonly) double duration;

- (WMAudioBuffer *)bufferByAppendingSampleBuffer:(CMSampleBufferRef)buffer;

@end
