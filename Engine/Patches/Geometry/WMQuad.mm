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

#import "WMStructuredBuffer.h"

#import <GLKit/GLKit.h>

struct WMQuadVertex {
	GLKVector3 p;
	GLKVector2 tc;
};

static WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat, .count = 3, .normalized = NO,  .offset = offsetof(WMQuadVertex, p)},
	{.name = "texCoord0", .type = WMStructureTypeFloat, .count = 2, .normalized = NO, .offset = offsetof(WMQuadVertex, tc)},
};


@implementation WMQuad {
	WMStructureDefinition *quadDef;
	WMRenderObject *renderObject;
	
	WMShader *shader;
	
	//The vertex buffer is cached for a given size/orientation pair. If either changes, it is regenerated.
	CGSize vertexBufferSize;
	UIImageOrientation vertexBufferOrientation;
	NSUInteger vertexBufferU;
	NSUInteger vertexBufferV;
	WMStructuredBuffer *vertexBuffer;
	WMStructuredBuffer *indexBuffer;

}

@synthesize inputImage;
@synthesize inputPosition;
@synthesize inputScale;
@synthesize inputRotation;
@synthesize inputColor;
@synthesize inputBlending;
@synthesize inputSubU;
@synthesize inputSubV;
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
	if (!vertexBuffer) {
		vertexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:quadDef];
	}
	
	NSUInteger uCount = MIN(MAX(1u, inputSubU.index), 256u) + 1;
	NSUInteger vCount = MIN(MAX(1u, inputSubV.index), 256u) + 1;

	//If the buffer doesn't need update, return
	if (CGSizeEqualToSize(inImage.contentSize, vertexBufferSize) && inImage.orientation == vertexBufferOrientation && vertexBufferU == uCount && vertexBufferV == vCount) {
		return;
	}
	
	//Scale width to 1
	
	const CGFloat aspectRatio = inImage.contentSize.height / inImage.contentSize.width;
	
	GLKVector3 basisU;
	GLKVector3 basisV;
	
	
	//If fitU, then scale the image to fit based on its U/width dimension. Otherwise use its V/height dimension.
	
	switch (inImage.orientation) {
		default:
		case UIImageOrientationUp:
			basisU = (GLKVector3){1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, 1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationUpMirrored:
			basisU = (GLKVector3){1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, -1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationDown:
			basisU = (GLKVector3){-1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, -1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationDownMirrored:
			basisU = (GLKVector3){-1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, 1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationLeft:
			basisU = (GLKVector3){0.0f, -1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationLeftMirrored:
			basisU = (GLKVector3){0.0f, 1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationRight:
			basisU = (GLKVector3){0.0f, 1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){-1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationRightMirrored:
			basisU = (GLKVector3){0.0f, 1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
	}
	
	//Delete existing vertex buffer data
	vertexBuffer.count = 0;
		
	//Add vertices
	for (int v=0, i=0; v<vCount; v++) {
		for (int u=0; u<uCount; u++, i++) {
			
			float uf = (float)u / (uCount - 1);
			float vf = (float)v / (vCount - 1);
			
			GLKVector3 point = (uf - 0.5f) * 2.0f * basisU + (vf - 0.5f) * 2.0f * basisV;
			
			const struct WMQuadVertex vertex = {
				.p = point,
				.tc = {uf, 1.0 - vf} //Flip y coord to account for differing coord systems
			};
			
			
			//Append to vertex buffer
			[vertexBuffer appendData:&vertex withStructure:quadDef count:1];
		}
	}
	
	//Create index data
	WMStructureDefinition *indexDef  = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	indexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexDef];
	for (int v=0; v<vCount-1; v++) {
		for (int u=0; u<uCount-1; u++) {
			const int i = u + v * uCount;
			const int next_i = i + uCount; //Next row
			const unsigned short twoTris[] = {
				i + 0, i + 1,       next_i + 0,
				i + 1, next_i + 0 , next_i + 1};
			[indexBuffer appendData:twoTris withStructure:indexDef count:6];
		}
	}
	
	vertexBufferSize = inImage.contentSize;
	vertexBufferOrientation = inImage.orientation;	
}


- (BOOL)setup:(WMEAGLContext *)context;
{
	//TODO: replace this with a user-specifiable shader
	
	renderObject = [[WMRenderObject alloc] init];

	//TODO: make a better system for default shaders!
	NSError *defaultShaderError = nil;
	NSString *vertexShader = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WMDefaultShader" withExtension:@"vsh"] encoding:NSASCIIStringEncoding error:&defaultShaderError];
	if (defaultShaderError) {
		NSLog(@"Error loading default vertex shader: %@", defaultShaderError);
		return NO;
	}
	
	NSString *fragmentShader = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WMDefaultShader" withExtension:@"fsh"] encoding:NSASCIIStringEncoding error:&defaultShaderError];
	if (defaultShaderError) {
		NSLog(@"Error loading default fragment shader: %@", defaultShaderError);
		return NO;
	}
	
	shader = [[WMShader alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader error:&defaultShaderError];
	if (defaultShaderError) {
		NSLog(@"Error loading default shader: %@", defaultShaderError);
		return NO;
	}

	renderObject.shader = shader;	
	
	quadDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:sizeof(WMQuadVertex_fields) / sizeof(WMStructureField) totalSize:sizeof(WMQuadVertex)];
	quadDef.shouldAlignTo4ByteBoundary = YES;
	
	inputRotation.minValue = -180.f;
	inputRotation.maxValue = 180.f;
	
	GL_CHECK_ERROR;

	NSLog(@"render object: %@", renderObject);

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
	
	ZAssert([shader.vertexAttributeNames containsObject:@"position"], @"Couldn't find position in shader");
	ZAssert([shader.vertexAttributeNames containsObject:@"texCoord0"], @"Couldn't find texCoord0 in shader");

	if (inputImage.image) {
		
		[self updateVertexBufferForImageIfNecessary:inputImage.image];
		
		renderObject.vertexBuffer = vertexBuffer;
		renderObject.indexBuffer = indexBuffer;
		
		switch (inputBlending.index) {
			default:
//			case QCBlendModeReplace:
//				renderObject.renderBlendState = 0;
//				break;
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
		
		[renderObject setValue:[NSValue valueWithBytes:&transform objCType:@encode(GLKMatrix4)] forUniformWithName:WMRenderObjectTransformUniformName];

		[renderObject setValue:inputColor.objectValue forUniformWithName:@"color"];
		
		
		outputObject.object = renderObject;
	} else {
		outputObject.object = nil;
	}

	return YES;
}

@end
