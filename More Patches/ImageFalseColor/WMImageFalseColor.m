//
//  WMImageFalseColor.m
//  WMViewer
//
//  Created by Warren Stringer

#import "WMImageFalseColor.h"

#import "WMEAGLContext.h"
#import "WMShader.h"
#import "WMFramebuffer.h"
#import "WMTexture2D.h"
#import "WMFramebuffer.h"
#import "WMMathUtil.h"
#import "WMRenderObject.h"
#import "WMStructuredBuffer.h"

typedef struct {
	float v[4];
	unsigned char tc[2];
	//TODO: Align to even power boundary?
} WMQuadVertex;

static WMStructureField WMQuadVertex_fields[] = {
	{.name = "a_position",  .type = WMStructureTypeFloat,        .count = 3, .normalized = NO,  .offset = offsetof(WMQuadVertex, v)},
	{.name = "a_texCoord",  .type = WMStructureTypeUnsignedByte, .count = 2, .normalized = YES, .offset = offsetof(WMQuadVertex, tc)},
};


@implementation WMImageFalseColor

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass(self)]];
	[pool drain];
}

+ (NSString *)category;
{
    return WMPatchCategoryImage;
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
	
	
	WMStructureDefinition *indexDef = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedByte];
	indexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexDef];
	
	//Add triangles
	unsigned char indexData[2 * 3] = {0,1,2, 1,2,3};
	
	[indexBuffer appendData:indexData withStructure:indexBuffer.definition count:2 * 3];
}

-(void) overwriteRgbPal:(unsigned char*)pali {

    for (int i =  0; i < 32; i++) { *pali++ = i*4; *pali++ = 0;   *pali++ = 0;   *pali++ = 255; }
    for (int i = 32; i >  0; i--) { *pali++ = i*4; *pali++ = 0;   *pali++ = 0;   *pali++ = 255; }
    for (int i =  0; i < 32; i++) { *pali++ = 0;   *pali++ = i*4; *pali++ = 0;   *pali++ = 255; }
    for (int i = 32; i >  0; i--) { *pali++ = 0;   *pali++ = i*4; *pali++ = 0;   *pali++ = 255; }
    for (int i =  0; i < 32; i++) { *pali++ = 0;   *pali++ = 0;   *pali++ = i*4; *pali++ = 255; }
    for (int i = 32; i >  0; i--) { *pali++ = 0;   *pali++ = 0;   *pali++ = i*4; *pali++ = 255; }
    for (int i =  0; i < 32; i++) { *pali++ = i*4; *pali++ = i*4; *pali++ = i*4; *pali++ = 255; }
    for (int i = 32; i >  0; i--) { *pali++ = i*4; *pali++ = i*4; *pali++ = i*4; *pali++ = 255; }
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
									 fragmentShader:combindedShader
											  error:NULL];
	
	[self loadQuadData];
	
    NSData *palette = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RainbowDark" ofType:@"pal"]];

    //[self overwriteRgbPal: [palette bytes]]; // test only
    
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
    
	[shader  release];   shader = nil;
	[fbo     release];      fbo = nil;
	[texMono release];  texMono = nil;
	[texPal  release];   texPal = nil;

}

- (void)renderFromTexture:(WMTexture2D *)inSourceTexture 
                toTexture:(WMTexture2D *)inDestinationTexture 
                   atSize:(CGSize)inSize 
                inContext:(WMEAGLContext *)inContext;
{		
	
	GL_CHECK_ERROR;
	
	//Set dest fbo
	inContext.boundFramebuffer = fbo;
	
	WMRenderObject *ro = [[WMRenderObject alloc] init];
	
	ro.vertexBuffer = vertexBuffer;
	ro.indexBuffer = indexBuffer;
	ro.shader = shader;

	//Resize out output texture to the correct size (power of two, to contain the size)
	NSUInteger destTextureWidth = nextPowerOf2(inSize.width);
	NSUInteger destTextureHeight = nextPowerOf2(inSize.height);
	[inDestinationTexture setData:NULL pixelFormat:inDestinationTexture.pixelFormat pixelsWide:destTextureWidth pixelsHigh:destTextureHeight contentSize:inSize];
	
	[fbo setColorAttachmentWithTexture:inDestinationTexture];
	//Make sure framebuffer has this texture
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);

	//Set uniform values
	[ro setValue:[NSNumber numberWithFloat:inputOffset.value] forUniformWithName:@"u_offset"];
	[ro setValue:inSourceTexture forUniformWithName:@"s_texMono"];
	[ro setValue:texPal forUniformWithName:@"s_texPal"];
	
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return /*NO*/;
	}
#endif

	[inContext renderObject:ro];
	[ro release];

}

- (void)assureFramebuffer:(WMFramebuffer **)inoutFramebuffer isOfWidth:(NSUInteger)inWidth height:(NSUInteger)inHeight;
{
	WMFramebuffer *framebuffer = *inoutFramebuffer;
	
	NSUInteger pixelsWide = inWidth;
	NSUInteger pixelsHigh = inHeight;

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
	
	texMono.orientation = inputImage.image.orientation;
	outputImage.image = texMono;
	
	//Discard temp texture content
	//[texMono discardData];

	return YES;
	
}

@end
