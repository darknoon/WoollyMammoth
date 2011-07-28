//
//  WMQuad.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"
#import "WMRenderCommon.h"

//Just renders a quad, nothing special :)
@class WMShader;
@class WMImagePort;
@class WMNumberPort;
@class WMColorPort;
@interface WMQuad : WMPatch {
	WMImagePort *inputImage;
	WMVector3Port *inputPosition;
	WMNumberPort *inputScale;
	WMNumberPort *inputRotation;
	WMColorPort *inputColor;
	
	WMIndexPort *inputBlending;
	WMShader *shader;
	
	WMRenderObjectPort *outputObject;
}

@end
