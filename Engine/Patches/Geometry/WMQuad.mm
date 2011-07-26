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

WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat, .count = 3, .normalized = NO},
	{.name = "texCoord0", .type = WMStructureTypeUnsignedByte,  .count = 2, .normalized = YES},
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
    return @"Billboard";
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCBillboard"]];
	[pool drain];
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputScale"]) {
		return [NSNumber numberWithFloat:2.0f];
	} else if ([inKey isEqualToString:@"inputColor"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:1.0f], @"red",
				[NSNumber numberWithFloat:1.0f], @"green",
				[NSNumber numberWithFloat:1.0f], @"blue",
				[NSNumber numberWithFloat:1.0f], @"alpha",
				nil];
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
//	if (!inImage) return nil;
	
	WMStructuredBuffer *vertexData = [[[WMStructuredBuffer alloc] initWithDefinition:quadDef] autorelease];
	
	const float scale = 0.5;

	struct WMVertex_v3f_tc2f {
		float p[3];
		char tc[2];
	};
	
	//Add vertices
	for (int y=0, i=0; y<2; y++) {
		for (int x=0; x<2; x++, i++) {
			
			const struct WMVertex_v3f_tc2f v = {
				.p = {((float)x - 0.5f) * 2.0f * scale, ((float)y - 0.5f) * 2.0f * scale, 0.0f},
				.tc = {(char)x * 255, (char)y * 255}
			};
			
			//Append to vertex buffer
			[vertexData appendData:&v withStructure:quadDef count:1];
		}
	}
	return vertexData;
}


- (BOOL)setup:(WMEAGLContext *)context;
{
	//TODO: replace this with a user-specifiable shader
	
	NSString *vertexShader = @"\
	attribute vec4 position;\
	attribute vec2 texCoord0;\
	uniform mat4 modelViewProjectionMatrix;\
	varying highp vec2 v_textureCoordinate;\
	void main()\
	{\
    gl_Position = modelViewProjectionMatrix * position;\
	v_textureCoordinate = vec2(1.0) - texCoord0.yx;\
	}";
	
	NSString *fragmentShader = @"\
	uniform sampler2D texture;\
	uniform lowp vec4 color;\
	varying highp vec2 v_textureCoordinate;\
	void main()\
	{\
	gl_FragColor = color * texture2D(texture, v_textureCoordinate);\
	}";
	
	NSLog(@"blah vector 3: %@", NSStringFromGLKVector3((GLKVector3){0.12345, 20.123456789123456789f, 12345667890}));
	
	renderObject = [[WMRenderObject alloc] init];

	shader = [[WMShader alloc] initWithVertexShader:vertexShader pixelShader:fragmentShader];
	renderObject.shader = shader;	
	
	quadDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:sizeof(WMQuadVertex_fields) / sizeof(WMStructureField)];
	quadDef.shouldAlignTo4ByteBoundary = YES;
	
	renderObject.vertexBuffer = [self vertexBufferForImage:inputImage.image];
	
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
	
	glUseProgram(shader.program);
	
	GL_CHECK_ERROR;
	
	//TODO: manage current texture bound state in WMEAGLContext
	if (inputImage.image) {
		glBindTexture(GL_TEXTURE_2D, [inputImage.image name]);
		[shader setIntValue:0 forUniform:@"texture"];
	} else {
		glBindTexture(GL_TEXTURE_2D, 0);
	}
	
	GL_CHECK_ERROR;

	GLKMatrix4 transform = GLKMatrix4Identity;
	transform = GLKMatrix4Scale(transform, inputScale.value, inputScale.value, 1.0f);
	transform = GLKMatrix4TranslateWithVector3(transform, inputPosition.v);
	transform = GLKMatrix4RotateZ(transform, inputRotation.value * M_PI / 180.f);
	transform = GLKMatrix4Multiply(transform, inContext.modelViewMatrix);
	GL_CHECK_ERROR;
	[shader setMatrix4Value:transform forUniform:@"modelViewProjectionMatrix"];
	GL_CHECK_ERROR;

	[shader setVector4Value:inputColor.v forUniform:@"color"];

	GL_CHECK_ERROR;

	[inContext renderObject:renderObject];

	return YES;
}

@end
