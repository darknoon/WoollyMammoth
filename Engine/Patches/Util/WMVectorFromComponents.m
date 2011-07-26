//
//  WMVectorFromComponents.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMVectorFromComponents.h"

@implementation WMVectorFromComponents

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	outputPort.v = (GLKVector4){inputX.value, inputY.value, inputZ.value, inputW.value};
	return YES;
}
																				

@end
