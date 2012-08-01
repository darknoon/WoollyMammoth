//
//  WMAudioBuffer.m
//  WMEdit
//
//  Created by Andrew Pouliot on 5/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMAudioBuffer.h"

@implementation WMAudioBuffer 

@synthesize sampleBuffers = _sampleBuffers;
@synthesize duration = _duration;

- (id)initWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
	if (!sampleBuffer) return nil;
	
	self = [super init];
	if (!self) return nil;
	
	CFRetain(sampleBuffer);
	_sampleBuffers = [[NSArray alloc] initWithObjects:(__bridge id)sampleBuffer, nil];
	
	CMTime time = CMSampleBufferGetOutputDuration(sampleBuffer);
	_duration = (double)time.value / time.timescale;

	return self;
}

- (void)dealloc
{
	for (id sampleBuffer in _sampleBuffers) {
		CFRelease( (__bridge CMSampleBufferRef)sampleBuffer );
	}
}

- (WMAudioBuffer *)bufferByAppendingSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
	if (!sampleBuffer) return nil;
	
	WMAudioBuffer *newBuffer = [[WMAudioBuffer alloc] init];
	
	//+1 all sample buffers in the new object
	CFRetain(sampleBuffer);
	for (id sampleBuffer in _sampleBuffers) {
		CFRetain( (__bridge CMSampleBufferRef)sampleBuffer );
	}

	newBuffer->_sampleBuffers = [_sampleBuffers arrayByAddingObject:(__bridge id)sampleBuffer];
	CMTime time = CMSampleBufferGetOutputDuration(sampleBuffer);
	newBuffer->_duration = _duration + (double)time.value / time.timescale;
	
	return newBuffer;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ %p with %d sample buffers>", self.class, self, _sampleBuffers.count];
}

- (NSString *)debugDescription;
{
	return [NSString stringWithFormat:@"<%@ %p with %d sample buffers %@>", self.class, self, _sampleBuffers.count, _sampleBuffers.description];
}

@end
