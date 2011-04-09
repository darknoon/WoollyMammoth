//
//  DNFramebuffer.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/7/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "DNFramebuffer.h"


@implementation DNFramebuffer
@synthesize framebufferWidth;
@synthesize framebufferHeight;

//- (id)init;
//{
//
//}

- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;
{
	self = [super init];
	if (!self) return nil;
	
	EAGLContext *context = [EAGLContext currentContext];
	
	// Create default framebuffer object.
	glGenFramebuffers(1, &framebufferObject);
	[self bind];
	
	// Create color render buffer and allocate backing store.
	glGenRenderbuffers(1, &colorRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:inLayer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
	//Attach color buffer
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
	
	//Create depth buffer
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer); 
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, framebufferWidth, framebufferHeight); 
	//Attach depth buffer
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	
	return self;
}

- (void)bind;
{
	glBindFramebuffer(GL_FRAMEBUFFER, framebufferObject);
}

- (BOOL)presentRenderbuffer;
{
	EAGLContext *context = [EAGLContext currentContext];

	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	
	const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
	glBindFramebuffer(GL_FRAMEBUFFER, framebufferObject);
	glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
	
	BOOL success = [context presentRenderbuffer:GL_RENDERBUFFER];
	
	if (!success) {
		DLog(@"Unable to present renderbuffer");
	}
	
	return success;
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
	[super dealloc];
	[self deleteFramebuffer];
}

@end
