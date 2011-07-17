//
//  WMImageFalseColor.m
//  WMViewer
//
//  Created by Andrew Pouliot on 5/20/11.
// 
//  Copyright 2011 Darknoon. All rights reserved.


#import "WMImageFalseColor.h"

#import "WMEAGLContext.h"
#import "WMShader.h"
#import "WMFramebuffer.h"
#import "WMTexture2D.h"
#import "WMFramebuffer.h"
#import "WMMathUtil.h"

typedef struct {
	float v[4];
	float tc[2];
	//TODO: Align to even power boundary?
} WMQuadVertex;

@implementation WMImageFalseColor

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass(self)]];
	[pool drain];
}

- (BOOL)setPlistState:(id)inPlist;
{
	return [super setPlistState:inPlist];
}

- (void)loadQuadData;
{	
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);
		
	//Add vertices
	WMQuadVertex vertexDataPtr[4] = {
		{
			.v = {-1, -1, 0, 1}, 
			.tc = {0, 0}
		},
		{
			.v = {1, -1, 0, 1}, 
			.tc = {1, 0}
		},
		{
			.v = {-1, 1, 0, 1}, 
			.tc = {0, 1}
		},
		{
			.v = {1, 1, 0, 1}, 
			.tc = {1, 1}
		}};	
	
	//Add triangles
	unsigned short indexData[2 * 3] = {0,1,2, 1,2,3}; 
	
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	glBufferData(GL_ARRAY_BUFFER, sizeof(WMQuadVertex) * 4, vertexDataPtr, GL_STATIC_DRAW); GL_CHECK_ERROR;
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof (unsigned short), indexData, GL_STATIC_DRAW); GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	BOOL ok = [super setup:context];
	if (!ok) return NO;
	
	NSError *error = nil;
	NSString *combindedShader = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WMImageFalseColor" ofType:@"glsl"]
														  encoding:NSUTF8StringEncoding
															 error:&error];
	if (!combindedShader) {
		NSLog(@"Coludn't load false color shader: %@", error);
	}
	
	shader = [[WMShader alloc] initWithVertexShader:combindedShader
										pixelShader:combindedShader];
	
	[self loadQuadData];

    NSData *palette = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RainbowLight" ofType:@"pal"]];
#if 1
    unsigned char *pali = (unsigned char *) [palette bytes];
    for (int i=0; i<32; i++) {
        *pali++ = i*4;
        *pali++ = 0;
        *pali++ = 0;
        *pali++ = 255;
    }
    for (int i=32; i>0; i--) {
        *pali++ = i*4;
        *pali++ = 0;
        *pali++ = 0;
        *pali++ = 255;
    }
    for (int i=0; i<32; i++) {
        *pali++ = 0;
        *pali++ = i*4;
        *pali++ = 0;
        *pali++ = 255;
    }
    for (int i=32; i>0; i--) {
        *pali++ = 0;
        *pali++ = i*4;
        *pali++ = 0;
        *pali++ = 255;
    }
    for (int i=0; i<32; i++) {
        *pali++ = 0;
        *pali++ = 0;
        *pali++ = i*4;
        *pali++ = 255;
    }
    for (int i=32; i>0; i--) {
        *pali++ = 0;
        *pali++ = 0;
        *pali++ = i*4;
        *pali++ = 255;
    }
    for (int i=0; i<32; i++) {
        *pali++ = i*4;
        *pali++ = i*4;
        *pali++ = i*4;
        *pali++ = 255;
    }
    for (int i=32; i>0; i--) {
        *pali++ = i*4;
        *pali++ = i*4;
        *pali++ = i*4;
        *pali++ = 255;
    }
#endif
    texPal = [[WMTexture2D alloc] initWithData:[palette bytes]
                                   pixelFormat:kWMTexture2DPixelFormat_RGBA8888 
                                    pixelsWide:256 
                                    pixelsHigh:1 
                                   contentSize:CGSizeMake(256, 1)];
    
	
	return ok;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	if (vbo) glDeleteBuffers(1, &vbo);
	if (ebo) glDeleteBuffers(1, &ebo);
	[shader release];
	shader = nil;
	[fbo release];
	fbo = nil;
	[texMono release];
	texMono = nil;
	[texPal release];
	texPal = nil;

}

- (void)renderFromTexture:(WMTexture2D *)inSourceTexture 
                toTexture:(WMTexture2D *)inDestinationTexture 
                   atSize:(CGSize)inSize 
                inContext:(WMEAGLContext *)inContext;
{		
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	GL_CHECK_ERROR;
	
	glUseProgram(shader.program);
    
	//Set dest fbo
	inContext.boundFramebuffer = fbo;
	
	//Resize out output texture to the correct size (power of two, to contain the size)
	NSUInteger destTextureWidth = nextPowerOf2(inSize.width);
	NSUInteger destTextureHeight = nextPowerOf2(inSize.height);
	[inDestinationTexture setData:NULL pixelFormat:inDestinationTexture.pixelFormat pixelsWide:destTextureWidth pixelsHigh:destTextureHeight contentSize:inSize];
	
	//Make sure framebuffer has this texture
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}
	[fbo setColorAttachmentWithTexture:inDestinationTexture];

	//Render blur quad into dest
	glViewport(0, 0, inSize.width, inSize.height);
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);

	int positionLocation = [shader attributeLocationForName:@"a_position"];
	int texCoordLocation = [shader attributeLocationForName:@"a_texCoord"];
	
	ZAssert(positionLocation != -1, @"Couldn't find position in shader!");
	ZAssert(texCoordLocation != -1, @"Couldn't find texCoord0 in shader!");
	
	unsigned int enableMask = 1 << positionLocation | 1 << texCoordLocation;
	[inContext setVertexAttributeEnableState:enableMask];
	
	[inContext setDepthState:0];
	
	//TODO: support alpha channel
	[inContext setBlendState: 0];
		
	size_t stride = sizeof(WMQuadVertex);
		
	
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	//Position
	glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, v));
	
	//TexCoord0
	glVertexAttribPointer(texCoordLocation, 2, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, tc));

	//Set uniform values
	int offsetUniform = [shader uniformLocationForName:@"u_offset"];
	if (offsetUniform != -1) {
		glUniform1f(offsetUniform, inputOffset.value);
	}

	int tex0 = [shader uniformLocationForName:@"s_texMono"];
	if (tex0 != -1) {
        glActiveTexture ( GL_TEXTURE0 );
		glBindTexture(GL_TEXTURE_2D, inSourceTexture.name);
		glUniform1i(tex0, 0);
	}
	
	int tex1 = [shader uniformLocationForName:@"s_texPal"];
	if (tex1 != -1) {
        
        glActiveTexture ( GL_TEXTURE1 );
		glBindTexture(GL_TEXTURE_2D, texPal.name);
		glUniform1i(tex1, 1);
        glActiveTexture ( GL_TEXTURE0 );
	}
	

	
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return /*NO*/;
	}
#endif

	glDrawElements(GL_TRIANGLES, 2 * 3, GL_UNSIGNED_SHORT, NULL);
    GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);	

}

- (void)assureFramebuffer:(WMFramebuffer **)inoutFramebuffer isOfWidth:(NSUInteger)inWidth height:(NSUInteger)inHeight;
{
	WMFramebuffer *framebuffer = *inoutFramebuffer;
	
	NSUInteger pixelsWide = nextPowerOf2(inWidth);
	NSUInteger pixelsHigh = nextPowerOf2(inHeight);

	if (!framebuffer || framebuffer.framebufferWidth != pixelsWide || framebuffer.framebufferHeight != pixelsHigh) {
		//Re-create framebuffer and texture
		[framebuffer release];
				
		WMTexture2D *texture = [[WMTexture2D alloc] initWithData:NULL
													 pixelFormat:kWMTexture2DPixelFormat_RGBA8888
													  pixelsWide:pixelsWide
													  pixelsHigh:pixelsHigh
													 contentSize:(CGSize){inWidth, inHeight}];
		framebuffer = [[WMFramebuffer alloc] initWithTexture:texture depthBufferDepth:0];
		[texture release];
		
		if (!texture || !framebuffer) {
		} else {
			NSLog(@"Created framebuffer: %@", framebuffer);
		}
	}
	*inoutFramebuffer = framebuffer;

}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	NSUInteger renderWidth = inputImage.image.pixelsWide;
	NSUInteger renderHeight = inputImage.image.pixelsHigh;
	
	//No image to render from
	if (renderWidth == 0 || renderHeight == 0) {
		return YES;
	}
	
	if (!texMono) {
		texMono = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_RGBA8888 pixelsWide:64 pixelsHigh:64 contentSize:CGSizeZero];
	}
	if (!texPal) {
		texPal = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_RGBA8888 pixelsWide:64 pixelsHigh:64 contentSize:CGSizeZero];
	}
	if (!fbo) {
		fbo = [[WMFramebuffer alloc] initWithTexture:texMono depthBufferDepth:0];
	}
	
	//Bind this fbo for rendering
	WMFramebuffer *prevFramebuffer = context.boundFramebuffer;
		
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
//	NSLog(@"Render false pal %@ => %@", inputImage, texture);
	[self renderFromTexture:inputImage.image toTexture:texMono atSize:inputImage.image.contentSize inContext:context];
	
	//Restore previous settings
	context.boundFramebuffer = prevFramebuffer;
	glViewport(0, 0, context.boundFramebuffer.framebufferWidth, context.boundFramebuffer.framebufferHeight);

	outputImage.image = texMono;
	
	//Discard temp texture content
	[texMono discardData];

	return YES;
	
}

@end
