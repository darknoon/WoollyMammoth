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
	WMBooleanPort *inputRender;
	WMIndexPort *inputTarget;
	WMBooleanPort *inputMipmaps;
	WMIndexPort *inputWidth;
	WMIndexPort *inputHeight;
	WMImagePort *outputImage;

	BOOL useDepthBuffer;
    WMFramebuffer *framebuffer;
	WMTexture2D *texture;
}

@end
