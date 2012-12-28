//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"
#import "WMShader.h"
#import <GLKit/GLKMath.h>

enum {
	DNGLStateBlendEnabled = 1 << 0,
	DNGLStateBlendModeAdd = 1 << 1, //otherwise blend is source-over
} ;
typedef int DNGLStateBlendMask;

enum {
	DNGLStateDepthTestEnabled  = 1 << 0,
	DNGLStateDepthWriteEnabled = 1 << 1,
};
typedef int DNGLStateDepthMask;

@class WMFramebuffer;
@class WMTexture2D;
@class WMRenderObject;
@class WMVertexArrayObject;
@class CAEAGLLayer;

#if TARGET_OS_IPHONE
@interface WMEAGLContext : EAGLContext
#elif TARGET_OS_MAC
@class EAGLSharegroup;
@interface WMEAGLContext : NSObject

- (id)initWithOpenGLContext:(NSOpenGLContext *)context;

@property (nonatomic, readonly) EAGLSharegroup *sharegroup;
@property (nonatomic, readonly) NSOpenGLContext *openGLContext;

//TODO: figure out another way to handle this
- (void)setViewport:(CGRect)desiredViewport;

//We had some state mutated behind our back. Deal with it.
- (void)wm__assumeBoundFramebufferHack;

#endif

//Some objects should have gl state backing, some not
//ie WMStructuredBuffer only has gl backing when actually being used to render, transparent to the user
//ie WMRenderObject only has a VAO backing when actually going to be rendered to the screen

+ (WMEAGLContext *)currentContext;
+ (BOOL)setCurrentContext:(WMEAGLContext *)context;

/////// Caching methods  ///////

// Used by various parts of the render system to avoid duplication of shaders etc
- (id)cachedObjectForKey:(NSString *)key;
- (void)setCachedObject:(id)object forKey:(NSString *)key;

////// Rendering functions ///////

- (void)renderToFramebuffer:(WMFramebuffer *)inFramebuffer block:(void (^)())renderingOperations;

//Perform the following render operations in a RTT framebuffer, resulting in an output texture
- (WMTexture2D *)renderToTextureWithWidth:(GLuint)width height:(GLuint)height block:(void (^)())renderingOperations;
- (WMTexture2D *)renderToTextureWithWidth:(GLuint)width height:(GLuint)height depthBufferDepth:(GLuint)depth block:(void (^)())renderingOperations;

//The following functions must be nested within a previous call to renderToFramebuffer or renderToTexture...

//Main rendering function, draws to the current framebuffer
- (void)renderObject:(WMRenderObject *)inObject;

//Clears the color buffer to the given color
- (void)clearToColor:(GLKVector4)inColor;

//Clears the depth buffer to the default depth (+inf?)
- (void)clearDepth;

////// Implementation information ///////

@property (nonatomic, readonly) int maxTextureSize;
@property (nonatomic, readonly) int maxVertexAttributes;
@property (nonatomic, readonly) int maxTextureUnits;

/////// Debug aids  ///////

- (void)pushDebugGroup:(NSString *)group;
- (void)popDebugGroup;
- (void)insertDebugText:(NSString *)text;

@end
