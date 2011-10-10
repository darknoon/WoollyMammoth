//
//  Created by Andrew Pouliot on 7/25/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMStructuredBuffer.h"

@interface WMStructuredBuffer ()  {
	//For the WMEAGLContext's use
	NSMutableIndexSet *dirtySet;
	unsigned int bufferObject;
}

@end

@interface WMStructuredBuffer (WMStructuredBuffer_WMEAGLContext_Private) 

//A structured buffer can be uploaded to the GPU and have a representation there
@property (nonatomic) GLuint bufferObject;

//Type is GL_ARRAY_BUFFER or GL_ELEMENT_ARRAY_BUFFER
- (BOOL)uploadToBufferObjectIfNecessaryOfType:(GLenum)inBufferType inContext:(WMEAGLContext *)inContext;

- (NSIndexSet *)dirtyIndexSet;
- (void)resetDirtyIndexSet;

@end