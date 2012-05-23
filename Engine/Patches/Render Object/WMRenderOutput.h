//
//  WMRenderableOutput.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMRenderOutput : WMPatch {
	WMRenderObjectPort *inputRenderable1;
	WMRenderObjectPort *inputRenderable2;
	WMRenderObjectPort *inputRenderable3;
	WMRenderObjectPort *inputRenderable4;
}
//TODO: add inputs as inputs are connected to this patch

@end
