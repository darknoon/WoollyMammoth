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
	@autoreleasepool {
		[self registerPatchClass];
	}
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
	
    NSData *palette __attribute__((objc_precise_lifetime)) __attribute__((objc_precise_lifetime)) = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RainbowDark" ofType:@"pal"]];

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
	   shader = nil;
	   texPal = nil;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	NSUInteger renderWidth = inputImage.image.pixelsWide;
	NSUInteger renderHeight = inputImage.image.pixelsHigh;
	
	//No image to render from
	if (renderWidth == 0 || renderHeight == 0) {
		return YES;
	}
	
	if (!texPal) {
		texPal = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_RGBA8888 pixelsWide:64 pixelsHigh:64 contentSize:CGSizeZero];
	}
	if (!fbo) {
		fbo = [[WMFramebuffer alloc] initWithTexture:texMono depthBufferDepth:0];
	}

	outputImage.image = [context renderToTextureWithWidth:renderWidth height:renderHeight block:^{
		WMRenderObject *ro = [[WMRenderObject alloc] init];
		
		ro.vertexBuffer = vertexBuffer;
		ro.indexBuffer = indexBuffer;
		ro.shader = shader;
		
		//Set uniform values
		[ro setValue:[NSNumber numberWithFloat:inputOffset.value] forUniformWithName:@"u_offset"];
		[ro setValue:inputImage.image forUniformWithName:@"s_texMono"];
		[ro setValue:texPal forUniformWithName:@"s_texPal"];
		
		[context clearToColor:(GLKVector4){0,0,0,0}];
		[context renderObject:ro];
	}];
	outputImage.image.orientation = inputImage.image.orientation;

	return YES;
	
}

@end
