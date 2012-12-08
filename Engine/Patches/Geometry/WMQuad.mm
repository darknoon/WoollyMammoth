//
//  WMQuad.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMQuad.h"

#import "WMEAGLContext.h"

#import "WMNumberPort.h"
#import "WMImagePort.h"
#import "WMColorPort.h"
#import "WMTexture2D.h"
#import "WMFramebuffer.h"
#import "WMRenderObject.h"
#import "WMRenderObject+CreateWithGeometry.h"

#import "WMStructuredBuffer.h"

#import <GLKit/GLKit.h>

@implementation WMQuad {
	WMStructureDefinition *quadDef;
	WMRenderObject *renderObject;
		
	//The vertex buffer is cached for a given size/orientation pair. If either changes, it is regenerated.
	CGSize vertexBufferSize;
	UIImageOrientation vertexBufferOrientation;
	NSUInteger vertexBufferU;
	NSUInteger vertexBufferV;
}

//TODO: convert to new style
@synthesize inputImage;
@synthesize inputPosition;
@synthesize inputScale;
@synthesize inputRotation;
@synthesize inputColor;
@synthesize inputBlending;
@synthesize inputSubU;
@synthesize inputSubV;
@synthesize inputTransform;
@synthesize outputObject;

+ (NSString *)category;
{
    return WMPatchCategoryGeometry;
}

+ (NSString *)humanReadableTitle {
    return @"Rectangle with Image";
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputScale"]) {
		return [NSNumber numberWithFloat:1.0f];
	}
	return nil;
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	return self;
}

- (void)updateVertexBufferForImageIfNecessary:(WMTexture2D *)inImage;
{
	NSUInteger uCount = MIN(MAX(1u, inputSubU.index), 256u) + 1;
	NSUInteger vCount = MIN(MAX(1u, inputSubV.index), 256u) + 1;

	//If the buffer doesn't need update, return
	if (renderObject && CGSizeEqualToSize(inImage.contentSize, vertexBufferSize) && inImage.orientation == vertexBufferOrientation && vertexBufferU == uCount && vertexBufferV == vCount) {
		return;
	}
	
	renderObject = [WMRenderObject quadRenderObjectWithTexture2D:inImage uSubdivisions:uCount vSubdivisions:vCount];
	vertexBufferU = uCount;
	vertexBufferV = vCount;
	
	vertexBufferSize = inImage.contentSize;
	vertexBufferOrientation = inImage.orientation;	
}


- (BOOL)setup:(WMEAGLContext *)context;
{
	inputRotation.minValue = -180.f;
	inputRotation.maxValue = 180.f;
	
	GL_CHECK_ERROR;

	//DLog(@"render object: %@", renderObject);

	GL_CHECK_ERROR;

	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	renderObject = nil;
	
	GL_CHECK_ERROR;
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	GL_CHECK_ERROR;
	
	if (inputImage.image) {
		
		[self updateVertexBufferForImageIfNecessary:inputImage.image];
		
		switch (inputBlending.index) {
			default:
			case QCBlendModeReplace:
				renderObject.renderBlendState = 0;
				break;
			case QCBlendModeOver:
				renderObject.renderBlendState = DNGLStateBlendEnabled;
				break;
			case QCBlendModeAdd:
				renderObject.renderBlendState = DNGLStateBlendEnabled | DNGLStateBlendModeAdd;
				break;
		}
						
		if (inputImage.image) {
			[renderObject setValue:inputImage.image forUniformWithName:@"texture"];
		}
		
		GLKMatrix4 transform = GLKMatrix4Identity;
		transform = GLKMatrix4RotateZ(transform, inputRotation.value * M_PI / 180.f);
		transform = GLKMatrix4TranslateWithVector3(transform, inputPosition.v);
		transform = GLKMatrix4Scale(transform, inputScale.value, inputScale.value, 1.0f);
		transform = GLKMatrix4Multiply(transform, inputTransform.v);
		
		[renderObject setValue:[NSValue valueWithBytes:&transform objCType:@encode(GLKMatrix4)] forUniformWithName:WMRenderObjectTransformUniformName];

		[renderObject setValue:inputColor.objectValue forUniformWithName:@"color"];
		
		renderObject.debugLabel = self.key;
		outputObject.object = renderObject;
	} else {
		outputObject.object = nil;
	}

	return YES;
}

@end
