//
//  WMRenderObject+CreateWithGeometry.h
//  DadaBubble
//
//  Created by Andrew Pouliot on 11/19/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMRenderObject.h"

@interface WMRenderObject (CreateWithGeometry)

/**
 @abstract Create a quad with the given frame
 @discussion Index and vertex buffers are set, but no shader provided. Vertices are in "position", texture coords are in "texCoord0"
 @param frame The extent of the quad in gl coords
 */
+ (WMRenderObject *)quadRenderObjectWithFrame:(CGRect)frame;

/**
 @abstract Create a quad mesh with the shape of a given texture
 @discussion Index and vertex buffers are set, but no shader provided. Vertices are in "position", texture coords are in "texCoord0"
 @param texture The texture to model the shape after (aspect ratio)
 @param u Number of u subdivisions (useful if you have a vertex shader)
 @param v Number of v subdivisions (useful if you have a vertex shader)
 */
+ (WMRenderObject *)quadRenderObjectWithTexture2D:(WMTexture2D *)texture uSubdivisions:(NSUInteger)u vSubdivisions:(NSUInteger)v;

@end
