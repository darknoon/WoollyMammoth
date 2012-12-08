//
//  DNGLState.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMEAGLContext.h"
#import "WMShader.h"
#import "WMFramebuffer.h"
#import "WMStructuredBuffer.h"
#import "WMRenderObject.h"
#import "WMTexture2D.h"
#import "WMTexture2D_RenderPrivate.h"

#import "WMStructuredBuffer_WMEAGLContext_Private.h"
#import "WMTexture2D_WMEAGLContext_Private.h"
#import "WMRenderObject_WMEAGLContext_Private.h"
#import "WMGLStateObject_WMEAGLContext_Private.h"
#import "WMShader_WMEAGLContext_Private.h"
#import "WMVertexArrayObject.h"

#if TARGET_OS_IPHONE && GL_OES_vertex_array_object
#define glBindVertexArray glBindVertexArrayOES
#endif

//TODO: where should this live?
@interface WMShader (WMShader_Uniform_State)

//TODO: support multiple-input, ie 3 vec3s instead of 1
- (BOOL)setIntValue:(int)inValue forUniform:(NSString *)inUniform;
- (BOOL)setFloatValue:(float)inValue forUniform:(NSString *)inUniform;
- (BOOL)setVector2Value:(GLKVector2)inValue forUniform:(NSString *)inUniform;
- (BOOL)setVector3Value:(GLKVector3)inValue forUniform:(NSString *)inUniform;
- (BOOL)setVector4Value:(GLKVector4)inValue forUniform:(NSString *)inUniform;
- (BOOL)setMatrix3Value:(GLKMatrix3)inValue forUniform:(NSString *)inUniform;
- (BOOL)setMatrix4Value:(GLKMatrix4)inValue forUniform:(NSString *)inUniform;

@end

@interface WMEAGLContext ()

@property (nonatomic) DNGLStateBlendMask blendState;
@property (nonatomic) DNGLStateDepthMask depthState;

@property (nonatomic, strong) WMFramebuffer *boundFramebuffer;

@end

@implementation WMEAGLContext {
@public
	DNGLStateBlendMask blendState;
	DNGLStateDepthMask depthState;
	WMFramebuffer *boundFramebuffer;
	CGRect viewport;
	
	WMVertexArrayObject *boundVAO;
	
	NSCache *_objectCache;
	
	GLKVector4 clearColor;
	
	int activeTexture;
	//Only 0 ... maxTextureUnits is defined
	GLuint boundTextures2D[32];
	GLuint boundTexturesCube[32];
	
	int maxVertexAttributes;
	int maxTextureUnits;
}

@synthesize blendState;
@synthesize depthState;
@synthesize boundFramebuffer;
@synthesize maxTextureSize;
@synthesize maxTextureUnits;
@synthesize maxVertexAttributes;

+ (WMEAGLContext *)currentContext;
{
	EAGLContext *ctx = [super currentContext];
	ZAssert(!ctx || [ctx isKindOfClass:[WMEAGLContext class]], @"Not the expected context type!");
	return (WMEAGLContext *)ctx;
}

- (id)initWithAPI:(EAGLRenderingAPI)api;
{
	return [self initWithAPI:api sharegroup:nil];
}

- (id) initWithAPI:(EAGLRenderingAPI)api sharegroup:(EAGLSharegroup *)sharegroup {
	self = [super initWithAPI:api sharegroup:sharegroup];
	if (self == nil) return self; 
	
	BOOL success = [EAGLContext setCurrentContext:self];
	if (!success) {
		NSLog(@"Couldn't set current EAGLContext to self in WMEAGLContext initWithAPI:sharegroup:");
		return nil;
	}
	
	_objectCache = [[NSCache alloc] init];
	
	//Assumed state
	glEnable(GL_DEPTH_TEST);
	depthState = DNGLStateDepthTestEnabled | DNGLStateDepthWriteEnabled;
	
	//Assume an source-over mode to start
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTexture);
	activeTexture -= GL_TEXTURE0;
	
	glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &maxVertexAttributes);
	
	glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTextureUnits);
	
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
	
	return self;
}

- (WMGLStateObject *)cachedObjectForKey:(NSString *)key;
{
	return [_objectCache objectForKey:key];
}

- (void)setCachedObject:(WMGLStateObject *)object forKey:(NSString *)key;
{
	[_objectCache setObject:object forKey:key];
}

- (void)setBlendState:(int)inBlendState;
{
	if ((inBlendState & DNGLStateBlendEnabled) && !(blendState & DNGLStateBlendEnabled)) {
		//Enable blending
		glEnable(GL_BLEND);
	} else if (!(inBlendState & DNGLStateBlendEnabled) && (blendState & DNGLStateBlendEnabled)) {
		//Disable blending
		glDisable(GL_BLEND);
	}

	if ((inBlendState & DNGLStateBlendModeAdd) && !(blendState & DNGLStateBlendModeAdd)) {
		//Add mode
		glBlendFunc(GL_ONE, GL_ONE);
	} else if (!(inBlendState & DNGLStateBlendModeAdd) && (blendState & DNGLStateBlendModeAdd)) {
		//Source over
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	}
	blendState = inBlendState;
}

- (void)setDepthState:(int)inDepthState;
{
	if ((inDepthState & DNGLStateDepthTestEnabled) && !(depthState & DNGLStateDepthTestEnabled)) {
		//Turn on depth testing
		glDepthFunc(GL_LEQUAL);
		glEnable(GL_DEPTH_TEST);
	} else if (!(inDepthState & DNGLStateDepthTestEnabled) && (depthState & DNGLStateDepthTestEnabled)) {
		//Turn off depth testing
		glDepthFunc(GL_ALWAYS);
		glDisable(GL_DEPTH_TEST);
	}
	
	if ((inDepthState & DNGLStateDepthWriteEnabled) && !(depthState & DNGLStateDepthWriteEnabled)) {
		//Turn on depth writing
		glDepthMask(GL_TRUE);
		
	} else if (!(inDepthState & DNGLStateDepthWriteEnabled) && (depthState & DNGLStateDepthWriteEnabled)) {
		//Turn off depth writing
		glDepthMask(GL_FALSE);
	}
	
	depthState = inDepthState;
}

- (NSString *)description;
{
	NSMutableString *stateDesc = [NSMutableString string];
	
	[stateDesc appendFormat:@"\tblending %@\n", blendState & DNGLStateBlendEnabled ?  @"enabled" : @"disabled"];
	[stateDesc appendFormat:@"\tadd mode %@\n", blendState & DNGLStateBlendModeAdd ?  @"enabled" : @"disabled"];
	[stateDesc appendFormat:@"\tframebuffer: %@\n", boundFramebuffer];
	
	return [[super description] stringByAppendingFormat:@"{\n%@\n}", stateDesc];
}

- (void)setViewport:(CGRect)desiredViewport;
{
	if (!CGRectEqualToRect(desiredViewport, viewport)) {
		glViewport(desiredViewport.origin.x, desiredViewport.origin.y, desiredViewport.size.width, desiredViewport.size.height);
		viewport = desiredViewport;
	}
}

- (void)setBoundFramebuffer:(WMFramebuffer *)inFramebuffer;
{
	if (boundFramebuffer != inFramebuffer) {
		boundFramebuffer = inFramebuffer;
		
		if (boundFramebuffer) {
			[boundFramebuffer bind];
			CGRect desiredViewport = (CGRect){.size.width = boundFramebuffer.framebufferWidth, .size.height = boundFramebuffer.framebufferHeight};
			//Set viewport as necessary
			self.viewport = desiredViewport;
		} else {
			glBindFramebuffer(GL_FRAMEBUFFER, 0);
		}
	}
}

- (void)renderToFramebuffer:(WMFramebuffer *)inFramebuffer block:(void (^)())renderingOperations;
{
	//Make sure we are the current context, then nobody needs to worry about that :)
	[WMEAGLContext setCurrentContext:self];
	
	if (!inFramebuffer || !renderingOperations) return;
	
	WMFramebuffer *prev = self.boundFramebuffer;
	self.boundFramebuffer = inFramebuffer;
	renderingOperations();
	self.boundFramebuffer = prev;
}

//Perform the following render operations in a RTT framebuffer, resulting in an output texture
- (WMTexture2D *)renderToTextureWithWidth:(GLuint)width height:(GLuint)height block:(void (^)())renderingOperations;
{
	return [self renderToTextureWithWidth:width height:height depthBufferDepth:0 block:renderingOperations];
}

- (WMTexture2D *)renderToTextureWithWidth:(GLuint)width height:(GLuint)height depthBufferDepth:(GLuint)depth block:(void (^)())renderingOperations;
{
	//TODO: we can probably pool textures somehow, right?
	WMTexture2D *texture = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:width pixelsHigh:height contentSize:(CGSize){width, height}];
	//TODO: pull framebuffer from a pool or always reuse one (with the caveat being of course that popping the stack should work)
	WMFramebuffer *framebuffer = [[WMFramebuffer alloc] initWithTexture:texture depthBufferDepth:0];
	[self renderToFramebuffer:framebuffer block:renderingOperations];
	return texture;
}


- (void)renderObject:(WMRenderObject *)inObject;
{
	GL_CHECK_ERROR;

	//Can't render!
	if (!inObject.vertexBuffer || !inObject.shader) {
		NSLog(@"Can't render invalid render object: %@", inObject);
		return;
	}
	
	WMShader *shader = inObject.shader;
	
	//Make sure we have a VBO or EBO for the object in the GL state
	
	//Make sure vertex buffer is uploaded to GPU
	[inObject.vertexBuffer uploadToBufferObjectIfNecessaryOfType:GL_ARRAY_BUFFER inContext:self];
	[inObject.indexBuffer uploadToBufferObjectIfNecessaryOfType:GL_ELEMENT_ARRAY_BUFFER inContext:self];
	
	GL_CHECK_ERROR;
	
	//Create VAO
	[inObject createVAOIfNecessary];
	ZAssert(inObject.vertexArrayObject, @"No VAO set!");

	//Bind it
	if (![boundVAO isEqualToVertexArrayObject:inObject.vertexArrayObject]) {
		boundVAO = inObject.vertexArrayObject;
		glBindVertexArray(inObject.vertexArrayObject.glObject);
		GL_CHECK_ERROR;
	}

	GL_CHECK_ERROR;
	
	glUseProgram(shader.program);
	
	NSMutableOrderedSet *textures = [[NSMutableOrderedSet alloc] init];
	
	//Set uniform values
	for (NSString *uniformName in shader.uniformNames) {
		id value = [inObject valueForUniformWithName:uniformName];
		
		if ([value isKindOfClass:[NSNumber class]]) {
			[shader setFloatValue:[value floatValue] forUniform:uniformName];
		} else if ([value isKindOfClass:[NSValue class]]) {
			//TODO: use perfect hashing here!
			const char *valueType = [(NSValue *)value objCType];
			if (strcmp(valueType, @encode(GLKVector4)) == 0) {
				GLKVector4 vector;
				[(NSValue *)value getValue:&vector];
				[shader setVector4Value:vector forUniform:uniformName];
			} else if (strcmp(valueType, @encode(GLKVector3)) == 0) {
				GLKVector3 vector;
				[(NSValue *)value getValue:&vector];
				[shader setVector3Value:vector forUniform:uniformName];
			} else if (strcmp(valueType, @encode(GLKVector2)) == 0) {
				GLKVector2 vector;
				[(NSValue *)value getValue:&vector];
				[shader setVector2Value:vector forUniform:uniformName];
			} else if (strcmp(valueType, @encode(GLKMatrix4)) == 0) {
				GLKMatrix4 matrix;
				[(NSValue *)value getValue:&matrix];
				[shader setMatrix4Value:matrix forUniform:uniformName];
			} else if (strcmp(valueType, @encode(GLKMatrix3)) == 0) {
				GLKMatrix3 matrix;
				[(NSValue *)value getValue:&matrix];
				[shader setMatrix3Value:matrix forUniform:uniformName];
			} else {
				NSLog(@"bad nsvalue type for uniform %@: %s", uniformName, valueType);
			}
		} else if ([value isKindOfClass:[WMTexture2D class]]) {
			//We unique the textures (one texture unit per texture) here by adding to a mutable ordered set then getting the index back out
			[textures addObject:value];
			int textureUnit = [textures indexOfObject:value];
			[shader setIntValue:textureUnit forUniform:uniformName];
		} else if (value) {
			DLog(@"Unsupported value %@ of class %@ for uniform name %@", value, [value class], uniformName);
		} else {
			DLog(@"WARNING: trying to render without a value for uniform %@. This can lead to unexpecetd results.", uniformName);
		}
	}
	
	//Bind textures as a separate pass
	for (int i=0; i<textures.count && i<maxTextureUnits; i++) {
		[self setBound2DTextureName:[(WMTexture2D *)[textures objectAtIndex:i] name] onTextureUnit:i];
	}
	GL_CHECK_ERROR;
	
	// Validate program before drawing. This is a good check, but only really necessary in a debug build.
#if DEBUG_OPENGL
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
	}
#endif
	GL_CHECK_ERROR;
	
	
	self.blendState = inObject.renderBlendState;
	self.depthState = inObject.renderDepthState;
	
	
	GL_CHECK_ERROR;

	
	if (inObject.indexBuffer) {
		NSRange safeRange = inObject.renderRange;
		safeRange.length = MIN(safeRange.length, inObject.indexBuffer.count - safeRange.location);
		
		//Get element buffer type
		WMStructureField f;
		BOOL found = [inObject.indexBuffer.definition getFieldNamed:@"" outField:&f];
		ZAssert(found, @"Couldn't get the element buffer description!");
		GLenum elementBufferType = f.type;
		
#if DEBUG_OPENGL
		{
			GLint elementBufferBinding;
			glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &elementBufferBinding);
			ZAssert(elementBufferBinding == inObject.indexBuffer.bufferObject, @"Incorrect element buffer binding");
		}
#endif
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, inObject.indexBuffer.bufferObject);
		
		const void *offset = (void *)(safeRange.location * inObject.indexBuffer.definition.size);
		glDrawElements(inObject.renderType, safeRange.length, elementBufferType, offset /*indicies from bound index buffer*/);
		GL_CHECK_ERROR;
				
	} else {
		NSRange safeRange = inObject.renderRange;
		safeRange.length = MIN(safeRange.length, inObject.vertexBuffer.count - safeRange.location);

		glDrawArrays(inObject.renderType, safeRange.location, safeRange.length);
		
	}
	
	//Unbind or can we leave it bound?
	glBindVertexArray(0);
	boundVAO = 0;
	
	//TODO: unbind unused textures, but keep used ones bound?
//	for (int i=0; i<textures.count && i<maxTextureUnits; i++) {
//		[self setBound2DTextureName:0 onTextureUnit:i];
//	}
	
}
- (void)clearToColor:(GLKVector4)inColor;
{
	if (!GLKVector4AllEqualToVector4(clearColor, inColor)) {
		clearColor = inColor;
		glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
	}
	glClear(GL_COLOR_BUFFER_BIT);
}

- (void)clearDepth;
{
	glClear(GL_DEPTH_BUFFER_BIT);
}

- (void)pushDebugGroup:(NSString *)group;
{
	glPushGroupMarkerEXT(0, [group cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)popDebugGroup;
{
	glPopGroupMarkerEXT();
}

- (void)insertDebugText:(NSString *)text;
{
	glInsertEventMarkerEXT(0, [text cStringUsingEncoding:NSASCIIStringEncoding]);
}


@end


@implementation WMStructuredBuffer (WMStructuredBuffer_WMEAGLContext_Private)

- (BOOL)uploadToBufferObjectIfNecessaryOfType:(GLenum)inBufferType inContext:(WMEAGLContext *)inContext;
{
	if (_bufferObject == 0) {
		glGenBuffers(1, &_bufferObject);
		_bufferObjectType = inBufferType;
	} else {
		ZAssert(_bufferObjectType == inBufferType, @"Cannot upload to a different buffer type!");
	}
	
	//TODO: use glBufferSubData() only on the dirty indices
	//TODO: allow user specify static or stream
	//TODO: also support glMapBuffer()
	if (dirtySet.count > 0) {
		glBindBuffer(inBufferType, _bufferObject);
		
		ZAssert(self.dataPointer, @"Unable to get data pointer");
		
		glBufferData(inBufferType, self.dataSize, self.dataPointer, GL_STATIC_DRAW);
		GL_CHECK_ERROR;
		
		glBindBuffer(inBufferType, 0);
		
		[self resetDirtyIndexSet];
	}
	
	return YES;
}

- (void)deleteInternalState;
{
	if (_bufferObject != 0) {
		glDeleteBuffers(1, &_bufferObject);
		_bufferObject = 0;
	}
}

- (GLuint)bufferObject;
{
	return _bufferObject;
}

- (void)setBufferObject:(GLuint)bufferObject;
{
	_bufferObject = bufferObject;
}

- (GLenum)bufferObjectType;
{
	return _bufferObjectType;
}

- (void)setBufferObjectType:(GLenum)bufferObjectType;
{
	ZAssert(bufferObjectType == GL_ARRAY_BUFFER || bufferObjectType || GL_ELEMENT_ARRAY_BUFFER, @"Bad buffer object type!");
	_bufferObjectType = bufferObjectType;
}

- (NSIndexSet *)dirtyIndexSet;
{
	return [dirtySet copy];
}

- (void)resetDirtyIndexSet;
{
	[dirtySet removeAllIndexes];
}

#if GL_OES_mapbuffer
- (void *)_mapGLBufferForWriting;
{
	ZAssert(self.bufferObjectType == GL_ARRAY_BUFFER || self.bufferObjectType == GL_ELEMENT_ARRAY_BUFFER, @"Either this object has not been mapped or it is mapped to the wrong type!");
	return glMapBufferOES(self.bufferObjectType, GL_WRITE_ONLY_OES);
}

- (void)_unmapGLBuffer;
{
	glUnmapBufferOES(self.bufferObjectType);
}
#endif

@end

@implementation WMEAGLContext (WMTexture2D_WMEAGLContext_Private)

- (void)setActiveTextureUnit:(int)inActiveTextureUnitNumber;
{
	ZAssert(inActiveTextureUnitNumber < maxTextureUnits, @"Invalid texture unit to bind:%d max:%d", inActiveTextureUnitNumber, maxTextureUnits);
	if (activeTexture != inActiveTextureUnitNumber && inActiveTextureUnitNumber < maxTextureUnits) {
		glActiveTexture(GL_TEXTURE0 + inActiveTextureUnitNumber);
		activeTexture = inActiveTextureUnitNumber;
	}
}

- (GLuint)bound2DTextureNameOnTextureUnit:(int)inTextureUnit;
{
	ZAssert(inTextureUnit < maxTextureUnits, @"Invalid texture unit to query:%d max:%d", inTextureUnit, maxTextureUnits);
	return boundTextures2D[inTextureUnit];
}

- (void)setBound2DTextureName:(GLuint)inTextureName onTextureUnit:(int)inTextureUnit;
{
	if (boundTextures2D[inTextureUnit] != inTextureName) {
		[self setActiveTextureUnit:inTextureUnit];
		glBindTexture(GL_TEXTURE_2D, inTextureName);
		boundTextures2D[inTextureUnit] = inTextureName;
	}
	//Just check that it is bound as we thought
#if DEBUG_OPENGL
	[self setActiveTextureUnit:inTextureUnit];
	int boundTexture;
	glGetIntegerv(GL_TEXTURE_BINDING_2D, &boundTexture);
	ZAssert(boundTexture == boundTextures2D[inTextureUnit], @"Not changed as we expected.");
#endif
}

//Assigns a texture unit for temporary use, returning if one bound to that texture. The current texture unit is set to whichever is used
- (void)bind2DTextureNameForModification:(GLuint)inTextureName inBlock:(void (^)())blockWithGLOperations;
{
	if (!blockWithGLOperations) return;
	//Find a texture unit on which this texture is already bound.
	for (int i=0; i<maxTextureUnits; i++) {
		if ([self bound2DTextureNameOnTextureUnit:i] == inTextureName) {
			[self setActiveTextureUnit:i];
			blockWithGLOperations();
			return;	
		}
	}
	//Otherwise, use texture unit 0 I guess
	[self setBound2DTextureName:inTextureName onTextureUnit:0];
	blockWithGLOperations();
}

- (void)forgetTexture2DName:(GLuint)inTextureName;
{
	for (int i=0; i<maxTextureUnits; i++) {
		if (boundTextures2D[i] == inTextureName) {
			boundTextures2D[i] = 0;
		}
	}
}

@end

@implementation WMRenderObject (WMRenderObject_WMEAGLContext_Private)
//These must be provided by the render object directly, so just make the compiler shut up.
@dynamic vertexArrayObject;
@dynamic vertexArrayObjectDirty;

- (void)createVAOIfNecessary;
{
	WMEAGLContext *context = self.context;

	WMStructureDefinition *vertexDefinition = self.vertexBuffer.definition;
	//Find each relevant thing in the shader, attempt to bind to a part of the buffer
	if (self.shader && self.vertexArrayObjectDirty) {
		NSMutableArray *buffers = [[NSMutableArray alloc] init];
		NSMutableOrderedSet *attributeNames = [[NSMutableOrderedSet alloc] init];
		NSMutableOrderedSet *attributeLocations = [[NSMutableOrderedSet alloc] init];
		
		for (NSString *attribute in self.shader.vertexAttributeNames) {
			int location = [self.shader attributeLocationForName:attribute];
			if (location != -1 && [vertexDefinition getFieldNamed:attribute outField:NULL]) {
				[buffers addObject:self.vertexBuffer];
				[attributeNames addObject:attribute];
				[attributeLocations addObject:[[NSNumber alloc] initWithInteger:location]];				
			}
		}
		self.vertexArrayObject = [[WMVertexArrayObject alloc] initWithVertexBuffers:buffers attributeNames:attributeNames attributeLocations:attributeLocations indexBuffer:self.indexBuffer];
		
		//Bind it
		if (![context->boundVAO isEqualToVertexArrayObject:self.vertexArrayObject]) {
			context->boundVAO = self.vertexArrayObject;
			glBindVertexArray(self.vertexArrayObject.glObject);
			GL_CHECK_ERROR;
		}
		
		[self.vertexArrayObject refreshGLObject];
		self.vertexArrayObjectDirty = NO;
		
	} else if (!self.shader) {
		NSLog(@"TODO: no shader defined");
	}
}

@end

@implementation WMShader (WMShader_Uniform_State)

//TODO: make this less verbose
//TODO: support attribute & uniform sizes

- (BOOL)setIntValue:(int)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniform1i(uniformLocation, inValue);
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)setFloatValue:(float)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniform1f(uniformLocation, inValue);
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)setVector2Value:(GLKVector2)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniform2f(uniformLocation, inValue.x, inValue.y);
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)setVector3Value:(GLKVector3)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniform3f(uniformLocation, inValue.x, inValue.y, inValue.z);
		return YES;
	} else {
		return NO;
	}
	
}

- (BOOL)setVector4Value:(GLKVector4)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniform4f(uniformLocation, inValue.x, inValue.y, inValue.z, inValue.w);
		return YES;
	} else {
		return NO;
	}
	
}

- (BOOL)setMatrix3Value:(GLKMatrix3)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniformMatrix3fv(uniformLocation, 1, NO, inValue.m);
		return YES;
	} else {
		return NO;
	}
	
}

- (BOOL)setMatrix4Value:(GLKMatrix4)inValue forUniform:(NSString *)inUniform;
{
	int uniformLocation = [self uniformLocationForName:inUniform];
	if (uniformLocation != -1) {
		glUniformMatrix4fv(uniformLocation, 1, NO, inValue.m);
		return YES;
	} else {
		return NO;
	}
}

@end

