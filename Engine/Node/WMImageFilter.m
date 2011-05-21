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

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCImageFilter"]];
	[pool drain];
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
										pixelShader:combindedShader
									   uniformNames:[NSArray arrayWithObjects:@"offset", @"sTexture", nil]];
	
	[self loadQuadData];
	
	return ok;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	if (vbo) glDeleteBuffers(1, &vbo);
	if (ebo) glDeleteBuffers(1, &ebo);
	[shader release];
	shader = nil;
	[framebuffer0 release];
	framebuffer0 = nil;
	[framebuffer1 release];
	framebuffer1 = nil;
}

- (void)renderBlurPassFromTexture:(WMTexture2D *)inTexture toFramebuffer:(WMFramebuffer *)outFramebuffer amountX:(float)inAmountX amountY:(float)inAmountY inContext:(WMEAGLContext *)inContext;
{
	//Set dest fbo
	inContext.boundFramebuffer = outFramebuffer;
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);

	unsigned int attributeMask = WMRenderableDataAvailablePosition | WMRenderableDataAvailableTexCoord0 | WMRenderableDataAvailableIndexBuffer;
	unsigned int shaderMask = [shader attributeMask];
	unsigned int enableMask = attributeMask & shaderMask;
	[inContext setVertexAttributeEnableState:enableMask];
	
	[inContext setDepthState:0];
	
	//TODO: support alpha channel
	[inContext setBlendState: 0];
		
	size_t stride = sizeof(WMQuadVertex);
		
	
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	//Position
	ZAssert(enableMask & WMRenderableDataAvailablePosition, @"Position issue");
	glVertexAttribPointer(WMShaderAttributePosition, 3, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, v));
	
	//TexCoord0
	ZAssert(enableMask & WMRenderableDataAvailableTexCoord0, @"tex coord 0 issue");
	glVertexAttribPointer(WMShaderAttributeTexCoord0, 2, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, tc));
	
	//Set uniform values
	int offsetUniform = [shader uniformLocationForName:@"offset"];
	if (offsetUniform != -1) {
		glUniform2f(offsetUniform, inAmountX, inAmountY);
	}
		
	int tex = [shader uniformLocationForName:@"sTexture"];
	if (tex != -1) {
		glBindTexture(GL_TEXTURE_2D, inTexture.name);
		glUniform1i(tex, 0);
	}
	
	GL_CHECK_ERROR;

	//Position
	glVertexAttribPointer(WMShaderAttributePosition, 4, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, v));
	ZAssert(enableMask & WMRenderableDataAvailablePosition, @"Position issue");
	
	//TexCoord0
	if (enableMask & WMRenderableDataAvailableTexCoord0) {
		glVertexAttribPointer(WMShaderAttributeTexCoord0, 2, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadVertex, tc));
	}

	GL_CHECK_ERROR;
	
	// Validate program before drawing. This is a good check, but only really necessary in a debug build.
	// DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return NO;
	}
#endif

	glDrawElements(GL_TRIANGLES, 2 * 3, GL_UNSIGNED_SHORT, NULL);
}

- (void)renderBlurFromTexture:(WMTexture2D *)inTexture toFramebuffer:(WMFramebuffer *)outFramebuffer withIntermediateFramebuffer:(WMFramebuffer *)tempFramebuffer inContext:(WMEAGLContext *)inContext;
{	
	glViewport(0, 0, outFramebuffer.framebufferWidth, outFramebuffer.framebufferHeight);

	
	//Bind VBO, EBO
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	GL_CHECK_ERROR;
	
	glUseProgram(shader.program);
	
	//TODO: use correct offsets here
	//TODO: downscale texture to increase blur effectiveness
	//TODO: use blur amount in calculation of passes
	CGSize amt = {1.5f / inTexture.pixelsWide, 1.5f / inTexture.pixelsHigh};
	
	//Do 1 pass from the in texture to the temp buffer to the out buffer
	[self renderBlurPassFromTexture:inTexture               toFramebuffer:tempFramebuffer amountX:0 amountY:amt.height inContext:inContext];
	[self renderBlurPassFromTexture:tempFramebuffer.texture toFramebuffer:outFramebuffer amountX:amt.width amountY:0.0f inContext:inContext];
	//Do n passes from the out buffer to the temp buffer to the out buffer again
	for (int i=0; i<10; i++) {
		[self renderBlurPassFromTexture:outFramebuffer.texture  toFramebuffer:tempFramebuffer amountX:0.0f amountY:amt.height inContext:inContext];
		[self renderBlurPassFromTexture:tempFramebuffer.texture toFramebuffer:outFramebuffer amountX:amt.width amountY:0.0f inContext:inContext];
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
	
	[self assureFramebuffer:&framebuffer0 isOfWidth:renderWidth height:renderHeight];
	[self assureFramebuffer:&framebuffer1 isOfWidth:renderWidth height:renderHeight];
	
	//Bind this fbo for rendering
	WMFramebuffer *prevFramebuffer = context.boundFramebuffer;
		
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
//	NSLog(@"Render blur %@ => %@", inputImage, texture);
	[self renderBlurFromTexture:inputImage.image toFramebuffer:framebuffer1 withIntermediateFramebuffer:framebuffer0 inContext:context];
	
	//Restore previous settings
	context.boundFramebuffer = prevFramebuffer;
	glViewport(0, 0, context.boundFramebuffer.framebufferWidth, context.boundFramebuffer.framebufferHeight);

	outputImage.image = framebuffer1.texture;

	return YES;
	
}

@end
