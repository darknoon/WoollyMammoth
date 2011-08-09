//
//  WMRenderObject.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderObject.h"

#import "WMStructuredBuffer.h"

@interface WMRenderObject()
//Private state for WMEAGLContext
@property (nonatomic) GLenum vertexArrayObject;
@property (nonatomic) BOOL vertexArrayObjectDirty;
@end

@implementation WMRenderObject {
	NSMutableDictionary *uniformValues;
	BOOL _wmeaglcontextprivate_vaoDirty;
}

@synthesize vertexBuffer;
@synthesize indexBuffer;
@synthesize shader;

@synthesize renderType;
@synthesize renderRange;
@synthesize renderBlendState;
@synthesize renderDepthState;

@synthesize vertexArrayObject = _wmeaglcontextprivate_vertexArrayObject;
@synthesize vertexArrayObjectDirty = _wmeaglcontextprivate_vaoDirty;

- (id)init;
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
	
	renderType = GL_TRIANGLES;
	renderRange = (NSRange){.length = NSIntegerMax};
    
	renderBlendState = 0;
	renderDepthState = 0;
	
	uniformValues = [[NSMutableDictionary alloc] init];
	
    return self;
}

- (void)dealloc;
{
    [vertexBuffer release];
	[indexBuffer release];
	[shader release];
    [super dealloc];
}

- (void)setVertexBuffer:(WMStructuredBuffer *)inVertexBuffer;
{
	if (vertexBuffer != inVertexBuffer) {
		_wmeaglcontextprivate_vaoDirty = YES;
		[vertexBuffer release];
		vertexBuffer = [inVertexBuffer retain];
	}
}

- (void)setIndexBuffer:(WMStructuredBuffer *)inIndexBuffer;
{
	if (indexBuffer != inIndexBuffer) {
		_wmeaglcontextprivate_vaoDirty = YES;
		[indexBuffer release];
		indexBuffer = [inIndexBuffer retain];
	}
}

+ (NSString *)stringFromGLRenderType:(GLenum)inType;
{
	if (inType >= GL_POINTS && inType <= GL_TRIANGLE_FAN) {
		NSString *names[] = {@"points", @"lines", @"line loop", @"line strip", @"triangles", @"triangle strip", @"triangle fan"};
		return names[inType - GL_POINTS];
	} else {
		return @"<invalid render type>";
	}
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ %p vb:%@ ib:%@ shader:%@ renderType:%@ range:%@ renderBlendState:%d renderDepthState:%d>",
			[self class], self, vertexBuffer, indexBuffer, shader, [WMRenderObject stringFromGLRenderType:renderType], NSStringFromRange(renderRange), renderBlendState, renderDepthState];
}

- (void)setValue:(id)inValue forUniformWithName:(NSString *)inUniformName;
{
	[uniformValues setObject:inValue forKey:inUniformName];
}

- (id)valueForUniformWithName:(NSString *)inUniformName;
{
	return [uniformValues objectForKey:inUniformName];
}

@end
