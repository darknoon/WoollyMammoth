//
//  WMCameraInputTexture.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 11/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMCameraInputTexture.h"

#import "VideoCapture.h"

@implementation WMCameraInputTexture

@synthesize active;

- (void)dealloc
{
	[super dealloc];
}


- (void)setActive:(BOOL)inActive;
{
	if (active != inActive) {
		GL_CHECK_ERROR;
		VideoCapture *cap = [VideoCapture sharedCapture];
		if (!cap.capturing) {
			[cap startCapture];
		}		
		GL_CHECK_ERROR;
		
		active = inActive;

	}
}

- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;
{
	if (isLoaded) return NO;
	
	//TODO: error checking
	isLoaded = YES;
	
	return YES;
}

- (GLuint)glTexture;
{
	if (!active) {
		self.active = YES;
	}
	return [[VideoCapture sharedCapture] getVideoTexture];
}


@end
