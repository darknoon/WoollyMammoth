//
//  WMEightfoldTilePatch.h
//  VideoLiveEffect
//
//  Created by Andrew Pouliot on 5/23/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class WMShader;
@class WMStructuredBuffer;

@interface WMEightfoldTilePatch : WMPatch {
	WMImagePort *inputImage;
	WMNumberPort *inputAngle;
	WMNumberPort *inputScale;
	WMNumberPort *inputOffsetX;
	WMNumberPort *inputOffsetY;
	WMColorPort *inputColor;
	
	WMRenderObjectPort *outputObject;
}

@end
