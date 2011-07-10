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
		
		//Set matrix to identity
		modelViewMatrix[0] = 1;
		modelViewMatrix[5] = 1;
		modelViewMatrix[10] = 1;
		modelViewMatrix[15] = 1;
		
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

- (void)setModelViewMatrix:(float[16])inModelViewMatrix;
{
	memcpy(modelViewMatrix, inModelViewMatrix, 16 * sizeof(float));
}

- (void)getModelViewMatrix:(float[16])outModelViewMatrix;
{
	memcpy(outModelViewMatrix, modelViewMatrix, 16 * sizeof(float));
}
@end
