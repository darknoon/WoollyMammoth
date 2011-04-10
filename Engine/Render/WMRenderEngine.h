//
//  WMRenderEngine.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

#import "Matrix.h"

@class WMShader;
@class WMEngine;
@class DNEAGLContext;
@class DNFramebuffer;
@class Texture2D;

@interface WMRenderEngine : NSObject {
	DNEAGLContext *context;
	
	MATRIX cameraMatrix;
		
	Texture2D *rttTexture;
	DNFramebuffer *rttFramebuffer;
	
	//Weak
	WMEngine *engine;
}

@property (nonatomic, retain) DNEAGLContext *context;

- (id)initWithEngine:(WMEngine *)inEngine;

- (void)drawFrameInRect:(CGRect)inBounds;

@end
