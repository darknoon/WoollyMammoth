//
//  Created by Andrew Pouliot on 7/25/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMStructuredBuffer.h"

@interface WMStructuredBuffer ()  {
	//For the WMEAGLContext's use
	NSMutableIndexSet *dirtySet;
	GLuint _bufferObject;
	GLenum _bufferObjectType;
}

@end

@interface WMStructuredBuffer (WMStructuredBuffer_WMEAGLContext_Private) 

//A structured buffer can be uploaded to the GPU and have a representation there
@property (nonatomic) GLuint bufferObject;
@property (nonatomic) GLenum bufferObjectType;

//Type is GL_ARRAY_BUFFER or GL_ELEMENT_ARRAY_BUFFER
- (BOOL)uploadToBufferObjectIfNecessaryOfType:(GLenum)inBufferType inContext:(WMEAGLContext *)inContext;

//TODO: support buffer mapping on the mac
//Private methods for implementing public method so we can implement in WMEAGLContext instead in WMStructuredBuffer
- (void *)_mapGLBufferForWriting;
- (void)_unmapGLBuffer;

- (NSIndexSet *)dirtyIndexSet;
- (void)resetDirtyIndexSet;

@end