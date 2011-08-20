//
//  WMVectorPort.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/25/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPort.h"

#import "WMRenderCommon.h"

//Abstract superclass. Use the ports below in your patches, which indicate the size of the vector.
//TODO: standardize on "value" instead of "v" for all ports
@interface WMVectorPort : WMPort
@end

@interface WMVector2Port : WMVectorPort
@property (nonatomic) GLKVector2 v;
@end

@interface WMVector3Port : WMVectorPort
@property (nonatomic) GLKVector3 v;
@end

@interface WMVector4Port : WMVectorPort
@property (nonatomic) GLKVector4 v;
@end
