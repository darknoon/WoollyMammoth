//
//  WMRenderInImage.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class WMFramebuffer;
@class WMTexture2D;

@interface WMRenderInImage : WMPatch {
	WMRenderObjectPort *inputObject1;
	WMRenderObjectPort *inputObject2;
	WMRenderObjectPort *inputObject3;
	WMRenderObjectPort *inputObject4;
	
	WMColorPort *inputClearColor;
	
	WMBooleanPort *inputRender;
	WMIndexPort *inputTarget;
	WMBooleanPort *inputMipmaps;
	WMIndexPort *inputWidth;
	WMIndexPort *inputHeight;
	
	WMImagePort *outputImage;
}

@end
