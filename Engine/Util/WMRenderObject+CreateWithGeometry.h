//
//  WMRenderObject+CreateWithGeometry.h
//  DadaBubble
//
//  Created by Andrew Pouliot on 11/19/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMRenderObject.h"

@interface WMRenderObject (CreateWithGeometry)

//Index and vertex buffers are set, but no shader provided
//Vertices are in "position", texture coords are in "texCoord0"
+ (WMRenderObject *)quadRenderObjectWithFrame:(CGRect)inFrame;

+ (WMRenderObject *)quadRenderObjectWithTexture2D:(WMTexture2D *)texture uSubdivisions:(NSUInteger)u vSubdivisions:(NSUInteger)v;

@end
