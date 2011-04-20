//
//  DNFramebuffer.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/7/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "DNFramebuffer.h"

#import "Texture2D.h"
#import "DNEAGLContext.h"

@implementation DNFramebuffer
@synthesize framebufferWidth;
@synthesize framebufferHeight;

- (id)initWithTexture:(Texture2D *)inTexture depthBufferDepth:(GLuint)inDepthBufferDepth;
{
	self = [super init];
	if (!self) return nil;
	
	DNEAGLContext *context = (DNEAGLContext *)[EAGLContext currentContext];
	ZAssert(context, @"nil current context creating RTT DNFramebuffer");
	ZAssert([context isKindOfClass:[DNEAGLContext class]], @"Cannot use DNFramebuffer without DNEAGLcontext");
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &framebufferObject);
	context.boundFramebuffer = self;

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
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		context.boundFramebuffer = nil;
		[self release];
		return nil;
	}
	
	return self;
}

- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;
{
	self = [super init];
	if (!self) return nil;
	
	DNEAGLContext *context = (DNEAGLContext *)[EAGLContext currentContext];
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &framebufferObject);
	context.boundFramebuffer = self;
	
	//ASSUMPTION: we don't care about stomping on currently bound renderbuffer state
	
	// Create color render buffer and allocate backing store.
	glGenRenderbuffers(1, &colorRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:inLayer];
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
	
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		[self release];
		return nil;
	}
	
	return self;
}

- (void)dealloc;
{
	[self deleteFramebuffer];
	[super dealloc];
}

- (void)bind;
{
	glBindFramebuffer(GL_FRAMEBUFFER, framebufferObject);
}

- (BOOL)presentRenderbuffer;
{
	DNEAGLContext *context = (DNEAGLContext *)[EAGLContext currentContext];
	
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

- (BOOL)hasDepthbuffer;
{
	return depthRenderbuffer != 0;
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

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{fbo: %u, color:%u depth:%u size:{%d, %d}}", NSStringFromClass([self class]), self, framebufferObject, colorRenderbuffer, depthRenderbuffer, framebufferWidth, framebufferHeight];
}

@end
