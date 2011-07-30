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
	char tc[2];
};

WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,        .count = 3, .normalized = NO,  .offset = offsetof(WMQuadVertex, p)},
	{.name = "texCoord0", .type = WMStructureTypeUnsignedByte, .count = 2, .normalized = YES, .offset = offsetof(WMQuadVertex, tc)},
};


@implementation WMQuad {
	WMStructureDefinition *quadDef;
	WMRenderObject *renderObject;
}

+ (NSString *)category;
{
    return WMPatchCategoryGeometry;
}

+ (NSString *)humanReadableTitle {
    return @"Rectangle with Image";
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"WMBillboard"]];
	[pool drain];
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

- (void) dealloc
{	
	[super dealloc];
}

- (WMPatchExecutionMode)executionMode;
{
	return kWMPatchExecutionModeConsumer;
}

- (WMStructuredBuffer *)vertexBufferForImage:(WMTexture2D *)inImage;
{
	if (!inImage) return nil;
	
	WMStructuredBuffer *vertexData = [[[WMStructuredBuffer alloc] initWithDefinition:quadDef] autorelease];
	
	//Scale width to 1
	
	const CGFloat aspectRatio = inImage.contentSize.height / inImage.contentSize.width;
	
	GLKVector3 basisU;
	GLKVector3 basisV;
	
	switch (inImage.orientation) {
		default:
		case UIImageOrientationUp:
			basisU = (GLKVector3){1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, 1.0f, 0.0f};
			break;
		case UIImageOrientationDown:
			basisU = (GLKVector3){-1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, -1.0f, 0.0f};
			break;
		case UIImageOrientationLeft:
			basisU = (GLKVector3){0.0f, -1.0f, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationRight:
			basisU = (GLKVector3){0.0f, 1.0f, 0.0f};
			basisV = (GLKVector3){-1.0f, 0.0f, 0.0f};
			break;
	}
		
	//Add vertices
	for (int v=0, i=0; v<2; v++) {
		for (int u=0; u<2; u++, i++) {
			
			GLKVector3 point = ((float)u - 0.5f) * 2.0f * basisU + ((float)v - 0.5f) * 2.0f * basisV / aspectRatio;
			
			const struct WMQuadVertex vertex = {
				.p = point,
				.tc = {255 - (char)v * 255, 255 - (char)u * 255}
			};
			
			//Append to vertex buffer
			[vertexData appendData:&vertex withStructure:quadDef count:1];
		}
	}
	return vertexData;
}


- (BOOL)setup:(WMEAGLContext *)context;
{
	//TODO: replace this with a user-specifiable shader
	
	renderObject = [[WMRenderObject alloc] init];
	
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
		
	GL_CHECK_ERROR;

	//Create index data
	WMStructureDefinition *indexDef  = [[[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort] autorelease];
	WMStructuredBuffer *indexBuffer = [[[WMStructuredBuffer alloc] initWithDefinition:indexDef] autorelease];
	[indexBuffer appendData:(unsigned short[]){0,1,2, 1,2,3} withStructure:indexDef count:6];
	
	renderObject.indexBuffer = indexBuffer;

	NSLog(@"render object: %@", renderObject);

	GL_CHECK_ERROR;

	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	[renderObject release];
	renderObject = nil;
	GL_CHECK_ERROR;

}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	GL_CHECK_ERROR;
	
	ZAssert([shader.vertexAttributeNames containsObject:@"position"], @"Couldn't find position in shader");
	ZAssert([shader.vertexAttributeNames containsObject:@"texCoord0"], @"Couldn't find texCoord0 in shader");

	if (inputImage.image) {
		renderObject.vertexBuffer = [self vertexBufferForImage:inputImage.image];
		
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
		transform = GLKMatrix4Scale(transform, inputScale.value, inputScale.value, 1.0f);
		transform = GLKMatrix4TranslateWithVector3(transform, inputPosition.v);
		transform = GLKMatrix4RotateZ(transform, inputRotation.value * M_PI / 180.f);
		transform = GLKMatrix4Multiply(transform, inContext.modelViewMatrix);
		[renderObject setValue:[NSValue valueWithBytes:&transform objCType:@encode(GLKMatrix4)] forUniformWithName:@"modelViewProjectionMatrix"];

		[renderObject setValue:inputColor.objectValue forUniformWithName:@"color"];
		
		
		outputObject.object = renderObject;
	}

	return YES;
}

@end
