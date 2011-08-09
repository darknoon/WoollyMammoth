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
#import "WMRenderObject.h"

typedef struct {
	float v[4];
	unsigned char tc[2];
} WMQuadVertex;

static WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,        .count = 3, .normalized = NO,  .offset = offsetof(WMQuadVertex, v)},
	{.name = "texCoord0", .type = WMStructureTypeUnsignedByte, .count = 2, .normalized = YES, .offset = offsetof(WMQuadVertex, tc)},
};

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
	WMStructureDefinition *vertexDef = [[[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:2 totalSize:sizeof(WMQuadVertex)] autorelease];
	vertexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:vertexDef];
	
	//Add vertices
	WMQuadVertex vertexDataPtr[4] = {
		{
			.v = {-1, -1, 0, 1}, 
			.tc = {0, 0}
		},
		{
			.v = {1, -1, 0, 1}, 
			.tc = {255, 0}
		},
		{
			.v = {-1, 1, 0, 1}, 
			.tc = {0, 255}
		},
		{
			.v = {1, 1, 0, 1}, 
			.tc = {255, 255}
		}};	
	
	[vertexBuffer appendData:vertexDataPtr withStructure:vertexBuffer.definition count:4];
	
	
	WMStructureDefinition *indexDef = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	indexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexDef];

	//Add triangles
	unsigned short indexData[2 * 3] = {0,1,2, 1,2,3};

	[indexBuffer appendData:indexData withStructure:indexBuffer.definition count:2 * 3];
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
		NSLog(@"Couldn't load blur shader: %@", error);
	}
	
	shader = [[WMShader alloc] initWithVertexShader:combindedShader
									 fragmentShader:combindedShader
											  error:NULL];
	
	[self loadQuadData];
	
	return ok;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	[vertexBuffer release];
	[indexBuffer release];
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
	
	//Resize out output texture to the correct size
	NSUInteger destTextureWidth = inSize.width;
	NSUInteger destTextureHeight = inSize.height;
//	if (inDestinationTexture.pixelsWide != destTextureWidth || inDestinationTexture.pixelsHigh != destTextureHeight)
	[inDestinationTexture setData:NULL pixelFormat:inDestinationTexture.pixelFormat pixelsWide:destTextureWidth pixelsHigh:destTextureHeight contentSize:inSize];
	
	//Make sure framebuffer has this texture
	[fbo setColorAttachmentWithTexture:inDestinationTexture];
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}

	WMRenderObject *ro = [[WMRenderObject alloc] init];
	
	ro.vertexBuffer = vertexBuffer;
	ro.indexBuffer = indexBuffer;
	ro.shader = shader;
	
	//Set uniform values
	
	const GLKVector2 offset = {inAmountX / 64, inAmountY / 64};
	[ro setValue:[NSValue valueWithBytes:&offset objCType:@encode(GLKVector2)] forUniformWithName:@"offset"];
	
	const GLKVector2 tcScale = {inSourceTexture.maxS, inSourceTexture.maxT};
	[ro setValue:[NSValue valueWithBytes:&tcScale objCType:@encode(GLKVector2)] forUniformWithName:@"tcScale"];
	
	[ro setValue:inSourceTexture forUniformWithName:@"sTexture"];
		
	GL_CHECK_ERROR;
	
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return /*NO*/;
	}
#endif

	//Render blur quad into dest
	[inContext clearToColor:(GLKVector4){0,0,0,0}];
	[inContext renderObject:ro];
	[ro release];
}

- (void)renderBlurFromTexture:(WMTexture2D *)inSourceTexture toTexture:(WMTexture2D *)inDestinationTexture atSize:(CGSize)inOutputSize withIntermediateTexture:(WMTexture2D *)inTempTexture inContext:(WMEAGLContext *)inContext;
{		
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
		
//	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
//	glClear(GL_COLOR_BUFFER_BIT);
//	NSLog(@"Render blur %@ => %@", inputImage, texture);
	[self renderBlurFromTexture:inputImage.image toTexture:texture1 atSize:inputImage.image.contentSize withIntermediateTexture:texture0 inContext:context];
	
	//Restore previous settings
	context.boundFramebuffer = prevFramebuffer;

	texture1.orientation = inputImage.image.orientation;
	
	outputImage.image = texture1;
	
	//Discard temp texture content
	[texture0 discardData];

	return YES;
	
}

@end
