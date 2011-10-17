//
//  WMSetRenderObject.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

//Either creates a render object (if vertices supplied), or modifies the object passed

@interface WMSetRenderObject : WMPatch

@property (nonatomic, retain) WMRenderObjectPort *inputObject;
@property (nonatomic, retain) WMRenderObjectPort *outputObject;


@property (nonatomic, retain) WMBufferPort *inputVertices;
@property (nonatomic, retain) WMBufferPort *inputIndices;


//TODO: add port(s) to set render range
//TODO:
//@property (nonatomic, retain) WMIndexPort *inputBlendingType; <- assumed src-over
//@property (nonatomic, retain) WMIndexPort *inputDepthType; <- assumed none
//@property (nonatomic, retain) WMIndexPort *inputRenderType; <- assumed triangles

@end
