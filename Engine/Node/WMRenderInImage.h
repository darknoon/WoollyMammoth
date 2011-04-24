//
//  WMRenderInImage.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class DNFramebuffer;
@class Texture2D;

@interface WMRenderInImage : WMPatch {
	WMBooleanPort *inputRender;
	WMIndexPort *inputTarget;
	WMBooleanPort *inputMipmaps;
	WMIndexPort *inputWidth;
	WMIndexPort *inputHeight;
	WMImagePort *outputImage;

	BOOL useDepthBuffer;
    DNFramebuffer *framebuffer;
	Texture2D *texture;
}

@end
