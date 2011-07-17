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

#import "WMStructuredBuffer.h"

#import "Matrix.h"

WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat, .count = 3, .normalized = NO},
	{.name = "texCoord0", .type = WMStructureTypeUnsignedByte,  .count = 2, .normalized = YES},
};


@implementation WMQuad {
	WMStructureDefinition *quadDef;
}

+ (NSString *)category;
{
    return WMPatchCategoryRender;
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
		return [NSNumber numberWithFloat:1.0f];
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
	
	
	
	shader = [[WMShader alloc] initWithVertexShader:vertexShader pixelShader:fragmentShader];
	
	

	const float scale = 0.5;
	
	quadDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:sizeof(WMQuadVertex_fields) / sizeof(WMStructureField)];
	quadDef.shouldAlignTo4ByteBoundary = YES;
	WMStructuredBuffer *vertexData = [[[WMStructuredBuffer alloc] initWithDefinition:quadDef] autorelease];
	
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
	
	//Upload to vbo
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);

	ZAssert(vertexData.dataPointer, @"Unable to get data pointer");
	glBufferData(GL_ARRAY_BUFFER, vertexData.dataSize, vertexData.dataPointer, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	//Create index data
	WMStructureDefinition *indexDef  = [[[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort] autorelease];
	WMStructuredBuffer *indexBuffer = [[[WMStructuredBuffer alloc] initWithDefinition:indexDef] autorelease];
	[indexBuffer appendData:(unsigned short[]){0,1,2, 1,2,3} withStructure:indexDef count:6];
	
	NSLog(@"vb: %@", vertexData);
	NSLog(@"ndixe: %@", indexBuffer);

	//Upload to ebo
	glGenBuffers(1, &ebo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBuffer.dataSize, indexBuffer.dataPointer, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	if (vbo) glDeleteBuffers(1, &vbo);
	if (ebo) glDeleteBuffers(1, &ebo);
	vbo = ebo = 0;
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	
	ZAssert([shader.vertexAttributeNames containsObject:@"position"], @"Couldn't find position in shader");
	ZAssert([shader.vertexAttributeNames containsObject:@"texCoord0"], @"Couldn't find texCoord0 in shader");

	//Find each relevant thing in the shader, attempt to bind to a part of the buffer
	unsigned int enableMask = 0;
	for (NSString *attribute in shader.vertexAttributeNames) {
		int location = [shader attributeLocationForName:attribute];
		if (location != -1 && [quadDef getFieldNamed:attribute outField:NULL outOffset:NULL]) {
			enableMask |= 1 << location;
		}
	}
	[inContext setVertexAttributeEnableState:enableMask];

	
	[inContext setDepthState:0];

	switch (inputBlending.index) {
		default:
		case QCBlendModeReplace:
			[inContext setBlendState:0];
			break;
		case QCBlendModeOver:
			[inContext setBlendState:DNGLStateBlendEnabled];
			break;
		case QCBlendModeAdd:
			[inContext setBlendState:DNGLStateBlendEnabled | DNGLStateBlendModeAdd];
			break;
	}
	
	glUseProgram(shader.program);
	
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);


	
	GL_CHECK_ERROR;

	for (NSString *attribute in shader.vertexAttributeNames) {
		int location = [shader attributeLocationForName:attribute];
		ZAssert(location != -1, @"Couldn't fined attribute: %@", attribute);
		if (location != -1) {
			WMStructureField f;
			NSUInteger offset = 0;
			if ([quadDef getFieldNamed:attribute outField:&f outOffset:&offset]) {
				glVertexAttribPointer(location, f.count, f.type, f.normalized, quadDef.size, (void *)offset);
			} else {
				//Couldn't bind anything to this.
				NSLog(@"Couldn't find data for attribute: %@", attribute);
			}
		}
	}
	
	GL_CHECK_ERROR;

	int textureUniformLocation = [shader uniformLocationForName:@"texture"];
	if (textureUniformLocation != -1) {
		if (inputImage.image) {
			glBindTexture(GL_TEXTURE_2D, [inputImage.image name]);
		} else {
			glBindTexture(GL_TEXTURE_2D, 0);
		}
		glUniform1i(textureUniformLocation, 0); //texture = texture 0
	}
	
	int matrixUniform = [shader uniformLocationForName:@"modelViewProjectionMatrix"];
	if (matrixUniform != -1) {
		//TODO: support transformation!
		MATRIX transform;
		MatrixIdentity(transform);
		
		MATRIX inputMatrix;
		[inContext getModelViewMatrix:inputMatrix.f];
		
		MATRIX scale;
		MatrixScaling(scale, inputScale.value, inputScale.value, 1.0f);

		MATRIX translation;
		MatrixTranslation(translation, inputX.value, inputY.value, 0.0f);

		//Translate, rotate, and scale
		MATRIX rotation;
		MatrixRotationZ(rotation, inputRotation.value * M_PI / 180.f);
		
		//Compose matrices
		MatrixMultiply(transform, transform, scale);
		MatrixMultiply(transform, transform, rotation);
		MatrixMultiply(transform, transform, translation);
		MatrixMultiply(transform, transform, inputMatrix);
		
		//TODO: support rotation
		glUniformMatrix4fv(matrixUniform, 1, NO, transform.f);
	}
	
	int colorUniform = [shader uniformLocationForName:@"color"];
	if (colorUniform != -1) {
		glUniform4f(colorUniform, inputColor.red, inputColor.green, inputColor.blue, inputColor.alpha);
	}

	// Validate program before drawing. This is a good check, but only really necessary in a debug build.
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return NO;
	}
#endif
	
	GL_CHECK_ERROR;
	
	glDrawElements(GL_TRIANGLES, 2 * 3, GL_UNSIGNED_SHORT, NULL);
	
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	return YES;
}

@end
