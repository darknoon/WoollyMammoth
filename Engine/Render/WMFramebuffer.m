//
//  WMFramebuffer.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/7/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMFramebuffer.h"

#import "WMTexture2D.h"
//This gives us access to the "name" attribute
#import "WMTexture2D_RenderPrivate.h"

//This allows us to modify the bound framebuffer
#import "WMFramebuffer_WMEAGLContext_Private.h"

#import "WMEAGLContext.h"

@interface WMFramebuffer ()

@property (weak, nonatomic, readonly) WMTexture2D *texture;

@end

@implementation WMFramebuffer {
	GLuint _colorRenderbuffer;
	GLuint _depthRenderbuffer;
	GLuint _framebufferObject;
}

+ (NSString *)descriptionOfFramebufferStatus:(GLenum)inStatus;
{
	switch (inStatus) {
		case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
			return @"Incomplete attachment";
		case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
			return @"Missing attachment";
		case GL_FRAMEBUFFER_COMPLETE:
			return @"Complete!";
		default:
			return @"??";

			//These symbols are ES only (ios)
#ifdef GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS
		case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
			return @"Incomplete Dimensions";
#endif
#ifdef GL_FRAMEBUFFER_UNSUPPORTED
		case GL_FRAMEBUFFER_UNSUPPORTED:
			return @"Unsupported";
#endif
#ifdef GL_APPLE_framebuffer_multisample
		case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE:
			return @"Incomplete multisample";
#endif
			
}
}

- (void)createAndAttachDepthBufferOfDepth:(GLuint)inDepthBufferDepth;
{
	if (inDepthBufferDepth > 0) {
		//Create depth buffer
		glGenRenderbuffers(1, &_depthRenderbuffer);	
		glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, inDepthBufferDepth, _framebufferWidth, _framebufferHeight);
		//Attach depth buffer
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
	}	
}

- (id)initWithTexture:(WMTexture2D *)inTexture depthBufferDepth:(GLuint)inDepthBufferDepth;
{
	if (!inTexture) return nil;
	
	self = [super init];
	if (!self) return nil;
	
	WMEAGLContext *context = [WMEAGLContext currentContext];
	ZAssert(context, @"nil current context creating RTT WMFramebuffer");
	ZAssert([context isKindOfClass:[WMEAGLContext class]], @"Cannot use WMFramebuffer without WMEAGLContext");
	
	WMFramebuffer *oldFrameBuffer = context.boundFramebuffer;
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &_framebufferObject);
	
	//WARNING: we're modifying state outside of WMEAGLContext. This method should therefore be moved to WMEAGLContext!
	[self bind];

	_texture = inTexture;
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, inTexture.name, 0);
	
	_framebufferWidth = inTexture.pixelsWide;
	_framebufferHeight = inTexture.pixelsHigh;
	
	[self createAndAttachDepthBufferOfDepth:inDepthBufferDepth];
	
	GL_CHECK_ERROR;
	
#if DEBUG_OPENGL
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		
		NSLog(@"Failed to make complete framebuffer object (%@) with texture %@", [WMFramebuffer descriptionOfFramebufferStatus:glCheckFramebufferStatus(GL_FRAMEBUFFER)], inTexture);
		
		[oldFrameBuffer bind];
		
		return nil;
	} else {
		//DLog(@"Created framebuffer %@ from texture: %@", self, inTexture);
	}
#endif
	
	[oldFrameBuffer bind];
	
	return self;
}

#if TARGET_OS_IPHONE

- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer depthBufferDepth:(GLuint)inDepthBufferDepth;
{
	self = [super init];
	if (!self) return nil;
	
	WMEAGLContext *context = [WMEAGLContext currentContext];
	
	WMFramebuffer *oldFrameBuffer = context.boundFramebuffer;
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &_framebufferObject);
	
	//WARNING: we're modifying state outside of WMEAGLContext. This method should therefore be moved to WMEAGLContext!
	[self bind];
	
	//ASSUMPTION: we don't care about stomping on currently bound renderbuffer state
	
	// Create color render buffer and allocate backing store.
	glGenRenderbuffers(1, &_colorRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
	BOOL storageOk = [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:inLayer];
	if (storageOk) {
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight);
		//Attach color buffer
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
		
		[self createAndAttachDepthBufferOfDepth:inDepthBufferDepth];
		
		GL_CHECK_ERROR;
	}
	
	
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		
		NSLog(@"Failed to make complete framebuffer object (%@) with layer %@", [WMFramebuffer descriptionOfFramebufferStatus:glCheckFramebufferStatus(GL_FRAMEBUFFER)], inLayer);

		[oldFrameBuffer bind];
		
		return nil;
	} else {
		//NSLog(@"Created framebuffer %@ from layer: %@", self, inLayer);
	}
	

	[oldFrameBuffer bind];
	
	return self;
}


- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;
{
	return [self initWithLayerRenderbufferStorage:inLayer depthBufferDepth:GL_DEPTH_COMPONENT16_OES];
}

#elif TARGET_OS_MAC

- (id)initWithNSOpenGLContext:(NSOpenGLContext *)nsOGLContext;
{
	self = [super init];
	if (!self) return nil;
	
	//yay, we're a fake framebuffer
	
	return self;

}

#endif

- (void)deleteInternalState;
{
	if (_framebufferObject)
	{
		glDeleteFramebuffers(1, &_framebufferObject);
		_framebufferObject = 0;
	}
	
	if (_colorRenderbuffer)
	{
		glDeleteRenderbuffers(1, &_colorRenderbuffer);
		_colorRenderbuffer = 0;
	}
	
	if (_depthRenderbuffer) {
		glDeleteRenderbuffers(1, &_depthRenderbuffer);
		_depthRenderbuffer = 0;
	}
	GL_CHECK_ERROR;
	
}

- (void)bind;
{
	glBindFramebuffer(GL_FRAMEBUFFER, _framebufferObject);
}

- (BOOL)presentRenderbuffer;
{
	
#if TARGET_OS_IPHONE
	
	WMEAGLContext *context = [WMEAGLContext currentContext];
	
	__block BOOL success = NO;
	[context renderToFramebuffer:self block:^{
#if 0
		const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
		glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
#endif 
		
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
		success = [context presentRenderbuffer:GL_RENDERBUFFER];
		
		if (!success) {
			DLog(@"Unable to present renderbuffer");
		}

	}];
	return success;

#endif
	
	return 1;
}

- (void)setColorAttachmentWithTexture:(WMTexture2D *)inTexture;
{
	WMEAGLContext *context = [WMEAGLContext currentContext];
	WMFramebuffer *oldFrameBuffer = context.boundFramebuffer;
	if (oldFrameBuffer != self) {
		context.boundFramebuffer = self;
	} else {
		CGRect desiredViewport = (CGRect){.size.width = inTexture.pixelsWide, .size.height = inTexture.pixelsHigh};
		context.viewport = desiredViewport;
	}
	
	GL_CHECK_ERROR;

	_texture = inTexture;
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, inTexture.name, 0);
		
	GL_CHECK_ERROR;

	_framebufferWidth = inTexture.pixelsWide;
	_framebufferHeight = inTexture.pixelsHigh;
	
#if DEBUG_OPENGL
	
	if (inTexture) {
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			NSLog(@"Failed to make complete framebuffer object (%@) with texture %@", [WMFramebuffer descriptionOfFramebufferStatus:glCheckFramebufferStatus(GL_FRAMEBUFFER)], inTexture);		
		}
	}
	
#endif
	
	context.boundFramebuffer = oldFrameBuffer;
}

- (BOOL)hasDepthbuffer;
{
	return _depthRenderbuffer != 0;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{fbo: %u, color:%u depth:%u texture:%@ size:{%d, %d}}", NSStringFromClass([self class]), self, _framebufferObject, _colorRenderbuffer, _depthRenderbuffer, _texture, _framebufferWidth, _framebufferHeight];
}

@end
