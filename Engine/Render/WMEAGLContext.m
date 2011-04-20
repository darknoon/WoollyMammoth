//
//  DNGLState.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMEAGLContext.h"
#import "WMShader.h"
#import "DNFramebuffer.h"

@implementation WMEAGLContext
@synthesize blendState;
@synthesize depthState;
@synthesize boundFramebuffer;

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
	
	for (int attribute=WMShaderAttributePosition; attribute<WMShaderAttributeCount; attribute++) {
		BOOL shouldBeEnabled = inVertexAttributeEnableState & (WMRenderableDataAvailablePosition << attribute);
		BOOL isEnabled = vertexAttributeEnableState & (WMRenderableDataAvailablePosition << attribute);
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
	for (int attribute=WMShaderAttributePosition; attribute<WMShaderAttributeCount; attribute++) {
		BOOL isEnabled = vertexAttributeEnableState & (WMRenderableDataAvailablePosition << attribute);
		NSString *attributeName = [WMShader nameForShaderAttribute:attribute];
		[stateDesc appendFormat:@"\t%@ %@\n", attributeName, isEnabled ? @"enabled" : @"disabled"];
	}
	
	[stateDesc appendFormat:@"\tblending %@\n", blendState & DNGLStateBlendEnabled ?  @"enabled" : @"disabled"];
	[stateDesc appendFormat:@"\tadd mode %@\n", blendState & DNGLStateBlendModeAdd ?  @"enabled" : @"disabled"];
	[stateDesc appendFormat:@"\tframebuffer: %@\n", boundFramebuffer];
	
	return [[super description] stringByAppendingFormat:@"{\n%@\n}", stateDesc];
}

- (void)setBoundFramebuffer:(DNFramebuffer *)inFramebuffer;
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

@end
