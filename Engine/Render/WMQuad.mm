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
#import "Texture2D.h"
#import "DNFramebuffer.h"

#import "Matrix.h"

typedef struct WMQuadVertex {
	float v[3];
	float tc[2];
	//TODO: Align to even power boundary?
};

@implementation WMQuad

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCBillboard"]];
	[pool drain];
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
	//TODO: figure out a good way to generate these programatically with #ifdefs in an omni-shader
	
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
	
	NSArray *uniforms = [NSArray arrayWithObjects:@"texture", @"modelViewProjectionMatrix", @"color", nil];
	
	shader = [[WMShader alloc] initWithVertexShader:vertexShader pixelShader:fragmentShader uniformNames:uniforms];
	
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);
	
	void *vertexData;
	unsigned short *indexData;
	
	vertexData = malloc(sizeof(WMQuadVertex) * 4);
	if (!vertexData) {
		DLog(@"malloc error");
		return NO;
	}
	
	const float scale = 0.5;
	
	//Add vertices
	WMQuadVertex *vertexDataPtr = (WMQuadVertex *)vertexData;
	for (int y=0, i=0; y<2; y++) {
		for (int x=0; x<2; x++, i++) {
			
			vertexDataPtr[i].v[0] = ((float)x - 0.5f) * 2.0f * scale;
			vertexDataPtr[i].v[1] = ((float)y - 0.5f) * 2.0f * scale;
			vertexDataPtr[i].v[2] = 0.0f;
			
			vertexDataPtr[i].tc[0] = (float)x;
			vertexDataPtr[i].tc[1] = (float)y;
		}
	}
	
	indexData = (unsigned short *)malloc(sizeof(indexData[0]) * 2 * 3); 
	if (!indexData) {
		DLog(@"malloc error");
		return NO;
	}
	//Add triangles
	indexData[0] = 0;
	indexData[1] = 1;
	indexData[2] = 2;
	
	indexData[3] = 1;
	indexData[4] = 2;
	indexData[5] = 3;
	
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	glBufferData(GL_ARRAY_BUFFER, sizeof(WMQuadVertex) * 4, vertexData, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof (unsigned short), indexData, GL_STATIC_DRAW);
	
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	
	if (vertexData) free(vertexData);
	if (indexData) free(indexData);
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	if (vbo) glDeleteBuffers(1, &vbo);
	if (ebo) glDeleteBuffers(1, &ebo);
}

- (unsigned int)dataMask;
{
	return WMRenderableDataAvailablePosition | WMRenderableDataAvailableTexCoord0 | WMRenderableDataAvailableIndexBuffer;
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	unsigned int attributeMask = WMRenderableDataAvailablePosition | WMRenderableDataAvailableTexCoord0 | WMRenderableDataAvailableIndexBuffer;
	unsigned int shaderMask = [shader attributeMask];
	unsigned int enableMask = attributeMask & shaderMask;
	[inContext setVertexAttributeEnableState:enableMask];
	
	[inContext setDepthState:0];
	
//	if ([blendMode isEqualToString:WMRenderableBlendModeAdd]) {
//		[inGLState setBlendState:DNGLStateBlendEnabled | DNGLStateBlendModeAdd];
//	} else {
//		[inGLState setBlendState:0];
//	}

	[inContext setBlendState: 0];
	
	glUseProgram(shader.program);
	
	size_t stride = sizeof(WMQuadVertex);
	
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);

	//Position
	glVertexAttribPointer(WMShaderAttributePosition, 3, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, v));
	ZAssert(enableMask & WMRenderableDataAvailablePosition, @"Position issue");
	
	//TexCoord0
	if (enableMask & WMRenderableDataAvailableTexCoord0) {
		glVertexAttribPointer(WMShaderAttributeTexCoord0, 2, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, tc));
	}
	
	int textureUniformLocation = [shader uniformLocationForName:@"texture"];
	if (textureUniformLocation) {
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
	// DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
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
