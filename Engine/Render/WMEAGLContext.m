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

#import "WMStructuredBuffer_WMEAGLContext_Private.h"

@implementation WMEAGLContext
@synthesize blendState;
@synthesize depthState;
@synthesize boundFramebuffer;
@synthesize modelViewMatrix;

- (id)initWithAPI:(EAGLRenderingAPI)api;
{
	return [self initWithAPI:api sharegroup:nil];
}

- (id) initWithAPI:(EAGLRenderingAPI)api sharegroup:(EAGLSharegroup *)sharegroup {
	self = [super initWithAPI:api sharegroup:sharegroup];
	if (self == nil) return self; 

	BOOL success = [EAGLContext setCurrentContext:self];
	
	if (success) {
		
		//Assumed state
		glEnable(GL_DEPTH_TEST);
		depthState = DNGLStateDepthTestEnabled | DNGLStateDepthWriteEnabled;
		
		//Assume an source-over mode to start
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		
		//Set matrix to identity
		modelViewMatrix = GLKMatrix4Identity;

		glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &maxVertexAttributes);
		
	} else {
		NSLog(@"Couldn't set current EAGLContext to self in WMEAGLContext initWithAPI:sharegroup:");
		[self release];
		return nil;
	}
	
	return self;
}

- (void)dealloc {
    [boundFramebuffer release];
	
    [super dealloc];
}


- (void)setVertexAttributeEnableState:(int)inVertexAttributeEnableState;
{
	if (vertexAttributeEnableState == inVertexAttributeEnableState) return;
	
	ZAssert(maxVertexAttributes < 32, @"We kind of assume that there are fewer than 32 possible attributes");

	for (int attribute=0; attribute<maxVertexAttributes; attribute++) {
		BOOL shouldBeEnabled = inVertexAttributeEnableState & (1 << attribute);
		BOOL isEnabled = vertexAttributeEnableState & (1 << attribute);
		if (shouldBeEnabled && !isEnabled) {
			glEnableVertexAttribArray(attribute);
		} else if (!shouldBeEnabled && isEnabled) {
			glDisableVertexAttribArray(attribute);
		}
	}
	vertexAttributeEnableState = inVertexAttributeEnableState;
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
	for (int attribute=0; attribute<maxVertexAttributes; attribute++) {
		BOOL isEnabled = vertexAttributeEnableState & (1 << attribute);
		[stateDesc appendFormat:@"\t%d %@\n", attribute, isEnabled ? @"on" : @"off"];
	}
	
	[stateDesc appendFormat:@"\tblending %@\n", blendState & DNGLStateBlendEnabled ?  @"enabled" : @"disabled"];
	[stateDesc appendFormat:@"\tadd mode %@\n", blendState & DNGLStateBlendModeAdd ?  @"enabled" : @"disabled"];
	[stateDesc appendFormat:@"\tframebuffer: %@\n", boundFramebuffer];
	
	return [[super description] stringByAppendingFormat:@"{\n%@\n}", stateDesc];
}

- (void)setBoundFramebuffer:(WMFramebuffer *)inFramebuffer;
{
	if (boundFramebuffer != inFramebuffer) {
		[boundFramebuffer release];
		boundFramebuffer = [inFramebuffer retain];
		
		if (boundFramebuffer) {
			[boundFramebuffer bind];
		} else {
			glBindFramebuffer(GL_FRAMEBUFFER, 0);
		}
	}
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
	WMStructureDefinition *vertexDefinition = inObject.vertexBuffer.definition;
	
	//Find each relevant thing in the shader, attempt to bind to a part of the buffer
	unsigned int enableMask = 0;
	if (shader) {
		for (NSString *attribute in inObject.shader.vertexAttributeNames) {
			int location = [shader attributeLocationForName:attribute];
			if (location != -1 && [vertexDefinition getFieldNamed:attribute outField:NULL outOffset:NULL]) {
				enableMask |= 1 << location;
			}
		}
		[self setVertexAttributeEnableState:enableMask];
	} else {
		NSLog(@"TODO: no shader defined");
	}

	//Make sure we have a VBO or EBO for the object
	
	//Make sure vertex buffer is uploaded to GPU
	if (inObject.vertexBuffer.bufferObject == 0) {
		[inObject.vertexBuffer uploadToBufferObjectOfType:GL_ARRAY_BUFFER inContext:self];
	}
	if (inObject.indexBuffer && inObject.indexBuffer.bufferObject == 0) {
		[inObject.indexBuffer uploadToBufferObjectOfType:GL_ELEMENT_ARRAY_BUFFER inContext:self];
	}
	
	GL_CHECK_ERROR;

	//TODO: keep track of bound buffer state to eleminate redundant binds / unbinds here
	glBindBuffer(GL_ARRAY_BUFFER, inObject.vertexBuffer.bufferObject);
	
	//Set up vertex state. 
	//TODO: use vao
	for (NSString *attribute in shader.vertexAttributeNames) {
		int location = [shader attributeLocationForName:attribute];
		ZAssert(location != -1, @"Couldn't fined attribute: %@", attribute);
		if (location != -1) {
			WMStructureField f;
			NSUInteger offset = 0;
			if ([vertexDefinition getFieldNamed:attribute outField:&f outOffset:&offset]) {
				glVertexAttribPointer(location, f.count, f.type, f.normalized, vertexDefinition.size, (void *)offset);
			} else {
				//Couldn't bind anything to this.
				NSLog(@"Couldn't find data for attribute: %@", attribute);
			}
		}
	}
	
	GL_CHECK_ERROR;
	
	
	// Validate program before drawing. This is a good check, but only really necessary in a debug build.
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
	}
#endif
	
	
	self.blendState = inObject.renderBlendState;
	self.depthState = inObject.renderDepthState;
	
	NSInteger first = inObject.renderRange.location;
	NSInteger last = NSMaxRange(inObject.renderRange);
	
	GL_CHECK_ERROR;

	
	if (inObject.indexBuffer) {
		last = MIN(last, inObject.indexBuffer.count - 1);
		
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, inObject.indexBuffer.bufferObject);
		
		//Get element buffer type
		WMStructureField f;
		[inObject.indexBuffer.definition getFieldNamed:nil outField:&f outOffset:NULL];
		GLenum elementBufferType = f.type;
#warning read properly
		elementBufferType = GL_UNSIGNED_SHORT;
		
		GL_CHECK_ERROR;
		glDrawElements(inObject.renderType, last - first + 1, elementBufferType, 0x0 /*indicies from bound index buffer*/);
		GL_CHECK_ERROR;
		
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
		
		GL_CHECK_ERROR;
		
		
	} else {
		
		//TODO: keep track of bound buffer state to eleminate redundant binds / unbinds here
		glBindBuffer(GL_ARRAY_BUFFER, inObject.vertexBuffer.bufferObject);
		
		last = MIN(last, inObject.vertexBuffer.count - 1);
		glDrawArrays(inObject.renderType, first, last - first + 1);
		
		
	}
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
}

- (GLuint)genBuffer;
{
	GLuint obj = 0;
	glGenBuffers(1, &obj);
	return obj;
}

- (void)destroyBuffer:(GLuint)inBufferObject;
{
	glDeleteBuffers(1, &inBufferObject);
}

@end


@implementation WMStructuredBuffer (WMStructuredBuffer_WMEAGLContext_Private)

- (BOOL)uploadToBufferObjectOfType:(GLenum)inBufferType inContext:(WMEAGLContext *)inContext;
{
	if (bufferObject == 0) {
		bufferObject = [inContext genBuffer];
	}
		
	glBindBuffer(inBufferType, bufferObject);
	
	ZAssert(self.dataPointer, @"Unable to get data pointer");
	
#warning allow user specify static or stream
	
	glBufferData(inBufferType, self.dataSize, self.dataPointer, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	
	glBindBuffer(inBufferType, 0);
	
	return YES;
}

- (void)releaseBufferObject;
{
	if (bufferObject != 0) {
		[(WMEAGLContext *)[WMEAGLContext currentContext] destroyBuffer:bufferObject];
	}
}

- (GLuint)bufferObject;
{
	return bufferObject;
}

- (void)setBufferObject:(GLuint)inBufferObject;
{
	bufferObject = inBufferObject;
}

@end
