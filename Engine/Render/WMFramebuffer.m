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

#import "WMEAGLContext.h"



@implementation WMFramebuffer
@synthesize framebufferWidth;
@synthesize framebufferHeight;
@synthesize texture;

+ (NSString *)descriptionOfFramebufferStatus:(GLenum)inStatus;
{
	switch (inStatus) {
		case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
			return @"Incomplete attachment";
		case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
			return @"Missing attachment";
		case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
			return @"Incomplete Dimensions";
		case GL_FRAMEBUFFER_UNSUPPORTED:
			return @"Unsupported";
		case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE:
			return @"Incomplete multisample";
		case GL_FRAMEBUFFER_COMPLETE:
			return @"Complete!";
		default:
			return @"??";
	}
}

- (id)initWithTexture:(WMTexture2D *)inTexture depthBufferDepth:(GLuint)inDepthBufferDepth;
{
	if (!inTexture) return nil;
	
	self = [super init];
	if (!self) return nil;
	
	WMEAGLContext *context = (WMEAGLContext *)[EAGLContext currentContext];
	ZAssert(context, @"nil current context creating RTT WMFramebuffer");
	ZAssert([context isKindOfClass:[WMEAGLContext class]], @"Cannot use WMFramebuffer without WMEAGLContext");
	
	WMFramebuffer *oldFrameBuffer = context.boundFramebuffer;
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &framebufferObject);
	
	//WARNING: we're modifying state outside of WMEAGLContext. This method should therefore be moved to WMEAGLContext!
	[self bind];

	texture = inTexture;
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, inTexture.name, 0);
	
	framebufferWidth = inTexture.pixelsWide;
	framebufferHeight = inTexture.pixelsHigh;
	
	if (inDepthBufferDepth > 0) {
		//Create depth buffer
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer); 
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, inDepthBufferDepth, framebufferWidth, framebufferHeight); 
		//Attach depth buffer
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	}
	
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		
		NSLog(@"Failed to make complete framebuffer object (%@) with texture %@", [WMFramebuffer descriptionOfFramebufferStatus:glCheckFramebufferStatus(GL_FRAMEBUFFER)], inTexture);
		
		[oldFrameBuffer bind];
		
		return nil;
	} else {
		DLog(@"Created framebuffer %@ from texture: %@", self, inTexture);
	}
	
	
	[oldFrameBuffer bind];
	
	return self;
}


- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;
{
	self = [super init];
	if (!self) return nil;
	
	WMEAGLContext *context = (WMEAGLContext *)[EAGLContext currentContext];
	
	WMFramebuffer *oldFrameBuffer = context.boundFramebuffer;
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &framebufferObject);
	
	//WARNING: we're modifying state outside of WMEAGLContext. This method should therefore be moved to WMEAGLContext!
	[self bind];
	
	//ASSUMPTION: we don't care about stomping on currently bound renderbuffer state
	
	// Create color render buffer and allocate backing store.
	glGenRenderbuffers(1, &colorRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	BOOL storageOk = [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:inLayer];
	if (storageOk) {
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
		//Attach color buffer
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
		
		//Create depth buffer
		glGenRenderbuffers(1, &depthRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER_OES, depthRenderbuffer); 
		glRenderbufferStorage(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, framebufferWidth, framebufferHeight); 
		//Attach depth buffer
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);

		GL_CHECK_ERROR;
	}
	
	
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		
		NSLog(@"Failed to make complete framebuffer object (%@) with layer %@", [WMFramebuffer descriptionOfFramebufferStatus:glCheckFramebufferStatus(GL_FRAMEBUFFER)], inLayer);

		[oldFrameBuffer bind];
		
		return nil;
	} else {
		NSLog(@"Created framebuffer %@ from layer: %@", self, inLayer);
	}
	

	[oldFrameBuffer bind];
	
	return self;
}

- (void)deleteFramebuffer;
{
	if (framebufferObject)
	{
		glDeleteFramebuffers(1, &framebufferObject);
		framebufferObject = 0;
	}
	
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffers(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	if (depthRenderbuffer) {
		glDeleteRenderbuffers(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
	GL_CHECK_ERROR;
	
}

- (void)dealloc;
{
	[self deleteFramebuffer];
}

- (void)bind;
{
	glBindFramebuffer(GL_FRAMEBUFFER, framebufferObject);
}

- (BOOL)presentRenderbuffer;
{
	WMEAGLContext *context = (WMEAGLContext *)[EAGLContext currentContext];
	
	context.boundFramebuffer = self;

#if 0
	const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
	glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
#endif 
	
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	BOOL success = [context presentRenderbuffer:GL_RENDERBUFFER];

	if (!success) {
		DLog(@"Unable to present renderbuffer");
	}
	
	return success;
}

- (void)setColorAttachmentWithTexture:(WMTexture2D *)inTexture;
{
	WMEAGLContext *context = (WMEAGLContext *)[EAGLContext currentContext];
	WMFramebuffer *oldFrameBuffer = context.boundFramebuffer;
	context.boundFramebuffer = self;
	
	texture = inTexture;
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, inTexture.name, 0);
	
	framebufferWidth = inTexture.pixelsWide;
	framebufferHeight = inTexture.pixelsHigh;
	
	context.boundFramebuffer = oldFrameBuffer;
}

- (BOOL)hasDepthbuffer;
{
	return depthRenderbuffer != 0;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{fbo: %u, color:%u depth:%u texture:%@ size:{%d, %d}}", NSStringFromClass([self class]), self, framebufferObject, colorRenderbuffer, depthRenderbuffer,  texture, framebufferWidth, framebufferHeight];
}

@end
