//
//  WMImageFilter.m
//  WMViewer
//
//  Created by Andrew Pouliot on 5/20/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMImageFilter.h"

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

@implementation WMImageFilter

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCImageFilter"]];
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
	
	glBufferData(GL_ARRAY_BUFFER, sizeof(WMQuadVertex) * 4, vertexDataPtr, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof (unsigned short), indexData, GL_STATIC_DRAW);
	
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	BOOL ok = [super setup:context];
	if (!ok) return NO;
	
	NSError *error = nil;
	NSString *combindedShader = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WMGaussianBlur" ofType:@"glsl"]
														  encoding:NSUTF8StringEncoding
															 error:&error];
	if (!combindedShader) {
		NSLog(@"Coludn't load blur shader: %@", error);
	}
	
	shader = [[WMShader alloc] initWithVertexShader:combindedShader
										pixelShader:combindedShader];
	
	[self loadQuadData];
	
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
	[texture0 release];
	texture0 = nil;
	[texture1 release];
	texture1 = nil;
}

- (void)renderBlurPassFromTexture:(WMTexture2D *)inSourceTexture toTexture:(WMTexture2D *)inDestinationTexture atSize:(CGSize)inSize amountX:(float)inAmountX amountY:(float)inAmountY inContext:(WMEAGLContext *)inContext;
{
	//Set dest fbo
	inContext.boundFramebuffer = fbo;
	
	//Resize out output texture to the correct size (power of two, to contain the size)
	NSUInteger destTextureWidth = nextPowerOf2(inSize.width);
	NSUInteger destTextureHeight = nextPowerOf2(inSize.height);
//	if (inDestinationTexture.pixelsWide != destTextureWidth || inDestinationTexture.pixelsHigh != destTextureHeight)
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

	int positionLocation = [shader attributeLocationForName:@"position"];
	int texCoordLocation = [shader attributeLocationForName:@"texCoord0"];
	
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
	int offsetUniform = [shader uniformLocationForName:@"offset"];
	if (offsetUniform != -1) {
		glUniform2f(offsetUniform, inAmountX / inSourceTexture.contentSize.width, inAmountY / inSourceTexture.contentSize.height);
	}

	int tcScaleUniform = [shader uniformLocationForName:@"tcScale"];
	if (tcScaleUniform != -1) {
		glUniform2f(tcScaleUniform, inSourceTexture.maxS, inSourceTexture.maxT);
	}

	int tex = [shader uniformLocationForName:@"sTexture"];
	if (tex != -1) {
		glBindTexture(GL_TEXTURE_2D, inSourceTexture.name);
		glUniform1i(tex, 0);
	}
	
	GL_CHECK_ERROR;
	
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return /*NO*/;
	}
#endif

	glDrawElements(GL_TRIANGLES, 2 * 3, GL_UNSIGNED_SHORT, NULL);
}

- (void)renderBlurFromTexture:(WMTexture2D *)inSourceTexture toTexture:(WMTexture2D *)inDestinationTexture atSize:(CGSize)inOutputSize withIntermediateTexture:(WMTexture2D *)inTempTexture inContext:(WMEAGLContext *)inContext;
{		
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	GL_CHECK_ERROR;
	
	glUseProgram(shader.program);
	
	//TODO: use correct offsets here
	//TODO: downscale texture to increase blur effectiveness
	//TODO: use blur amount in calculation of passes
	CGFloat amt = MIN(inputRadius.value, 5.0f);
	
	float amtNorm = amt / 5.0f;
	//Do 1 pass from the in texture to the temp buffer to the out buffer
	
	const float NONE = 0.0f;
	
	if (amt > 0.1f) {
		
		const float scales[] = {0.2f, 0.3f, 0.5f, 0.8f};
		const float amts[]   = {1.0f, 1.5f, 1.5f, 2.0f};
		
		//Pass 0...3
		for (int i=0; i<4; i++) {
			WMTexture2D *src = i==0 ? inSourceTexture : inDestinationTexture;
			WMTexture2D *dst = inDestinationTexture;
			WMTexture2D *tmp = inTempTexture;
			
			float scale = MIN(scales[i] / amtNorm, 1.0f);
			CGSize size = {floorf(scale * inSourceTexture.contentSize.width), floorf(scale * inSourceTexture.contentSize.height)};
			[self renderBlurPassFromTexture:src toTexture:tmp atSize:size amountX:amts[i] * amt amountY:NONE          inContext:inContext];
			[self renderBlurPassFromTexture:tmp toTexture:dst atSize:size amountX:NONE          amountY:amts[i] * amt inContext:inContext];
		}
		//Pass 4 => Write to output	
		[self renderBlurPassFromTexture:inDestinationTexture toTexture:inTempTexture atSize:inOutputSize amountX:1.0f * amt amountY:NONE inContext:inContext];
		[self renderBlurPassFromTexture:inTempTexture toTexture:inDestinationTexture atSize:inOutputSize amountX:NONE amountY:1.0f * amt inContext:inContext];
		
	} else {
		//Amount too small, do 1 pass
		[self renderBlurPassFromTexture:inSourceTexture toTexture:inTempTexture        atSize:inOutputSize amountX:1.0f * amt amountY:NONE inContext:inContext];
		[self renderBlurPassFromTexture:inTempTexture   toTexture:inDestinationTexture atSize:inOutputSize amountX:NONE amountY:1.0f * amt inContext:inContext];
	}
	
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
	
	//These will have their storage resized...
	if (!texture0) {
		texture0 = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_RGBA8888 pixelsWide:64 pixelsHigh:64 contentSize:CGSizeZero];
	}
	if (!texture1) {
		texture1 = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_RGBA8888 pixelsWide:64 pixelsHigh:64 contentSize:CGSizeZero];
	}
	if (!fbo) {
		fbo = [[WMFramebuffer alloc] initWithTexture:texture0 depthBufferDepth:0];
	}
	
	//Bind this fbo for rendering
	WMFramebuffer *prevFramebuffer = context.boundFramebuffer;
		
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
//	NSLog(@"Render blur %@ => %@", inputImage, texture);
	[self renderBlurFromTexture:inputImage.image toTexture:texture1 atSize:inputImage.image.contentSize withIntermediateTexture:texture0 inContext:context];
	
	//Restore previous settings
	context.boundFramebuffer = prevFramebuffer;
	glViewport(0, 0, context.boundFramebuffer.framebufferWidth, context.boundFramebuffer.framebufferHeight);

	outputImage.image = texture1;
	
	//Discard temp texture content
	[texture0 discardData];

	return YES;
	
}

@end
