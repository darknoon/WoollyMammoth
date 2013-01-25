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

NSString *WMImageFilterCacheKey = @"WMImageFilterShader";

@implementation WMImageFilter {
    WMShader *shader;
	
	WMFramebuffer *fbo;
	//Keep around textures at various sizes. We need two of each, which are called a and b
	//This is more efficient than recreating textures every frame.
	//Keys are nsstrings of the form "<width>x<height>-<a/b>"
	NSCache *_textureCache;
	
	//For quad
	WMRenderObject *_renderObject;
	WMStructuredBuffer *vertexBuffer;
	WMStructuredBuffer *indexBuffer;
}
@synthesize inputImage = inputImage;
@synthesize inputRadius = inputRadius;
@synthesize outputImage = outputImage;

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (BOOL)setPlistState:(id)inPlist;
{
	return [super setPlistState:inPlist];
}

- (void)loadQuadData;
{	
	WMStructureDefinition *vertexDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:2 totalSize:sizeof(WMQuadVertex)];
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
	_textureCache = [[NSCache alloc] init];
	[_textureCache setCountLimit:10];
	
	shader = (WMShader *)[[WMEAGLContext currentContext] cachedObjectForKey:WMImageFilterCacheKey];
	if (!shader) {
		NSError *error = nil;
		
#if TARGET_OS_IPHONE
		NSBundle *resourceBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"WMGraph" ofType:@"bundle"]];
		ZAssert(resourceBundle, @"Must include WMGraph.bundle in app resources to use WMImageFilter");
#elif TARGET_OS_MAC
		NSBundle *resourceBundle = [NSBundle bundleForClass:self.class];
#endif
		
		NSString *combindedShader = [NSString stringWithContentsOfFile:[resourceBundle pathForResource:@"WMGaussianBlur" ofType:@"glsl"]
															  encoding:NSUTF8StringEncoding
																 error:&error];
		if (!combindedShader) {
			NSLog(@"ERROR: Couldn't load blur shader: %@", error);
		}

		shader = [[WMShader alloc] initWithVertexShader:combindedShader
										 fragmentShader:combindedShader
												  error:NULL];
		[[WMEAGLContext currentContext] setCachedObject:shader forKey:WMImageFilterCacheKey];
	}

	
	[self loadQuadData];
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	_renderObject = nil;
	vertexBuffer = nil;
	indexBuffer = nil;
	shader = nil;
	fbo = nil;
	_textureCache = nil;
}

- (void)renderBlurPassFromTexture:(WMTexture2D *)inSourceTexture toTexture:(WMTexture2D *)inDestinationTexture amountX:(float)inAmountX amountY:(float)inAmountY inContext:(WMEAGLContext *)inContext;
{
#if DEBUG_OPENGL
	[inContext pushDebugGroup:@"WMBlurPass"];
#endif
	//Make sure framebuffer has this texture
	[fbo setColorAttachmentWithTexture:inDestinationTexture];

#if DEBUG_OPENGL
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}
#endif
	
	if (!_renderObject) {
		_renderObject = [[WMRenderObject alloc] init];
		_renderObject.debugLabel = self.key;
		
		_renderObject.vertexBuffer = vertexBuffer;
		_renderObject.indexBuffer = indexBuffer;
		_renderObject.shader = shader;
	}
	ZAssert(_renderObject, @"Need a render object");
	ZAssert(_renderObject.shader, @"Need a good shader");
	ZAssert(_renderObject.vertexBuffer, @"Need a good vertex buffer");
	ZAssert(_renderObject.indexBuffer, @"Need a good vertex buffer");
	
	//Set uniform values
	
	[_renderObject setValue:[NSValue valueWithGLKVector2:(GLKVector2){inAmountX / 64, inAmountY / 64}] forUniformWithName:@"offset"];
	[_renderObject setValue:[NSValue valueWithGLKVector2:(GLKVector2){inSourceTexture.maxS, inSourceTexture.maxT}] forUniformWithName:@"tcScale"];
	[_renderObject setValue:inSourceTexture forUniformWithName:@"sTexture"];
	
	GL_CHECK_ERROR;
	
#if DEBUG_OPENGL
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return /*NO*/;
	}
#endif

	//Render blur quad into dest
	[inContext clearToColor:(GLKVector4){0,0,0,0}];
	[inContext renderObject:_renderObject];

	[_renderObject setValue:nil forUniformWithName:@"sTexture"];
#if DEBUG_OPENGL
	[inContext popDebugGroup];
#endif
}

- (WMTexture2D *)_tempTextureOfSize:(CGSize)size keySuffix:(NSString *)key;
{
	NSString *textureUniqueCacheKey = [NSString stringWithFormat:@"%dx%d-%@", (uint32_t)size.width, (uint32_t)size.height, key];
	WMTexture2D *tempTexture = [_textureCache objectForKey:textureUniqueCacheKey];
	if (!tempTexture) {
		tempTexture = [[WMTexture2D alloc] initEmptyTextureWithPixelFormat:kWMTexture2DPixelFormat_RGBA8888 width:size.width height:size.height];
		[_textureCache setObject:tempTexture forKey:textureUniqueCacheKey];
	}
	return tempTexture;
}

- (WMTexture2D *)renderBlurFromTexture:(WMTexture2D *)inSourceTexture atSize:(CGSize)inOutputSize inContext:(WMEAGLContext *)inContext;
{
	//TODO: use correct offsets here
	//TODO: downscale texture to increase blur effectiveness
	//TODO: use blur amount in calculation of passes
	CGFloat amt = MIN(inputRadius.value, 5.0f);
	
	//Do 1 pass from the in texture to the temp buffer to the out buffer
	
	const float NONE = 0.0f;
	
	if (amt > 0.01f) {
		
		const float scales[] = {0.2f, 0.3f, 0.5f, 0.8f, 1.0f};
		const float amts[]   = {1.0f, 1.5f, 1.5f, 2.0f, 1.0f};
		
		float finalScales[5] = {};
		for (int i=0; i<5; i++) {
			finalScales[i] = MIN(scales[i] / amt, 0.5f);
		}
		
		//Pass 0...3
		WMTexture2D *src = inSourceTexture;
		for (int i=0; i<5; i++) {
			CGSize size = {
				.width  = floorf(finalScales[i] * inSourceTexture.contentSize.width),
				.height = floorf(finalScales[i] * inSourceTexture.contentSize.height)};
			
			WMTexture2D *tempTextureA = [self _tempTextureOfSize:size keySuffix:@"a"];
			WMTexture2D *tempTextureB = [self _tempTextureOfSize:size keySuffix:@"b"];
			
			[self renderBlurPassFromTexture:src          toTexture:tempTextureA amountX:amts[i] * amt amountY:NONE inContext:inContext];
			[self renderBlurPassFromTexture:tempTextureA toTexture:tempTextureB amountX:NONE          amountY:amts[i] * amt inContext:inContext];
			
			src = tempTextureB;
		}
		return src;
	} else {
		//Amount too small, do 1 pass
		CGSize size = inSourceTexture.contentSize;
		WMTexture2D *tempTextureA = [self _tempTextureOfSize:size keySuffix:@"a"];
		WMTexture2D *tempTextureB = [self _tempTextureOfSize:size keySuffix:@"b"];
		
		WMTexture2D *src = inSourceTexture;
		
		[self renderBlurPassFromTexture:src toTexture:tempTextureA  amountX:amt amountY:NONE inContext:inContext];
		[self renderBlurPassFromTexture:tempTextureA toTexture:tempTextureB amountX:NONE          amountY:amt inContext:inContext];
		
		return tempTextureB;
	}
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	ZAssert(self.hasSetup, @"Setup did not happen properly!");
	ZAssert(self.hasSetup && shader, @"Shader not compiled properly!");
	
	NSUInteger renderWidth = inputImage.image.pixelsWide;
	NSUInteger renderHeight = inputImage.image.pixelsHigh;
	
	//No image to render from
	if (renderWidth == 0 || renderHeight == 0) {
		return YES;
	}
	
	if (!fbo) {
		WMTexture2D *tex = [[WMTexture2D alloc] initEmptyTextureWithPixelFormat:kWMTexture2DPixelFormat_RGBA8888 width:64 height:64];
		fbo = [[WMFramebuffer alloc] initWithTexture:tex depthBufferDepth:0];
	}
	
	__block WMTexture2D *tex;
	//Bind this fbo for rendering
	[context renderToFramebuffer:fbo block:^{
		//	NSLog(@"Render blur %@ => %@", inputImage, texture);
		tex = [self renderBlurFromTexture:inputImage.image atSize:inputImage.image.contentSize inContext:context];
	}];

	tex.orientation = inputImage.image.orientation;
	
	outputImage.image = tex;
	
	//Discard temp texture content
	//[texture0 discardData];

	return YES;
	
}

@end
