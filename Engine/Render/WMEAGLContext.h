//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"
#import "WMShader.h"
#import <GLKit/GLKMath.h>

@class WMFramebuffer;
@class WMTexture2D;
@class WMRenderObject;
@class WMVertexArrayObject;
@class CAEAGLLayer;

/**
 @discussion WMEAGLContext wraps the context for the current platform (EAGLContext on iOS, NSOpenGLContext on Mac), providing a level of abstraction around OpenGL calls.
 
 ie WMStructuredBuffer only has gl backing when actually being used to render, transparent to the user
 ie WMRenderObject only has a VAO backing when actually going to be rendered to the screen
 
 @warning Do not use the OpenGL C apis in the same OpenGL context as the WMEAGLContext APIs. WMEAGLContext caches the internal state of the OpenGL state machine, so modifying the state outside the supported API may result in persistent inconsistencies or errors in rendering. If you need to do your own rendering, it is recommended to get OpenGL state before doing custom rendering and set it back to the same values after rendering.
 */

#if TARGET_OS_IPHONE
@interface WMEAGLContext : EAGLContext
#elif TARGET_OS_MAC
@class EAGLSharegroup;
@interface WMEAGLContext : NSObject
#endif

/** @name Current context */

/** Return the currently bound context for the current thread. */
+ (WMEAGLContext *)currentContext;
/** Set the currently bound context for the current thread. */
+ (BOOL)setCurrentContext:(WMEAGLContext *)context;

/** @name Caching */

/** Return a cached object */
- (id)cachedObjectForKey:(NSString *)key;
/** Cache an object associated with the current context. This is used by various parts of the render system to avoid duplication of shaders etc */
- (void)setCachedObject:(id)object forKey:(NSString *)key;

/** @name Rendering to framebuffers */

- (void)renderToFramebuffer:(WMFramebuffer *)inFramebuffer block:(void (^)())renderingOperations;

//Perform the following render operations in a RTT framebuffer, resulting in an output texture
- (WMTexture2D *)renderToTextureWithWidth:(GLuint)width height:(GLuint)height block:(void (^)())renderingOperations;
- (WMTexture2D *)renderToTextureWithWidth:(GLuint)width height:(GLuint)height depthBufferDepth:(GLuint)depth block:(void (^)())renderingOperations;


/** @name Rendering */

//The following functions must be nested within a previous call to renderToFramebuffer or renderToTexture...

/** @abstract The primary rendering API, draws with OpenGL to the current framebuffer
 @discussion This is the primary API for drawing. Create a WMRenderObject to specify the geometry, shader, and other rendering parameters, then call this function to render it. You can change the state of a render object and re-render within a given frame or across frames for efficiency.

 You must have a current framebuffer to use this API. A typical flow might look like:
 
     WMEAGLContext *context = view.context;
	 WMRenderObject *object = ...;
     [context renderToFramebuffer:view.framebuffer block:^{
	     [context renderObject:object];
     }];
 
 
 */
- (void)renderObject:(WMRenderObject *)inObject;

/** @abstract Clears the color buffer to the given color
 @discussion To clear to a UIColor, use the -componentsAsRGBAGLKVector4 convenience method, defined in <WM/GLKMathUICompatibility.h>
 */
- (void)clearToColor:(GLKVector4)inColor;

/** @abstract Clears the depth buffer.
 @discussion Call this method at the beginning of rendering if you're using the depth buffer.
 */
- (void)clearDepth;

/** @name Implementation information */

/** @abstract Maximum dimension of a texture
 @discussion Devices vary in the maximum texture size they support.
 
 Common values are 2048 (iPhone 3GS+, iPad 1) or 4096 (iPhone 4+, iPad 2+)
 */
@property (nonatomic, readonly) int maxTextureSize;

/** @abstract Maximum number of vertex attribute inputs to a shader
 @discussion A maximum of 16 vextex attributes is common on iOS
*/
@property (nonatomic, readonly) int maxVertexAttributes;

/** @abstract Maximum number of textures that can be sampled in a fragment shader
 @discussion A maximum of 8 textures is common on iOS.
 */
@property (nonatomic, readonly) int maxTextureUnits;

/** @name Debugging */

/** @abstract Push a debug group marker (iOS)
 @discussion Groups calls in between -pushDebugGroup: and -popDebugGroup calls into a folder when debugging with the OpenGL ES debugger
 @param group An NSString representable with ASCII characters
 */
- (void)pushDebugGroup:(NSString *)group;

/** @abstract Pop the current debug group marker (iOS)
 @discussion Groups calls in between -pushDebugGroup: and -popDebugGroup calls into a folder when debugging with the OpenGL ES debugger
 */
- (void)popDebugGroup;

/** @abstract Add a debug text item (iOS) */
- (void)insertDebugText:(NSString *)text;

@end

// Mac support is still considered experimental, and this interface may change in the future

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
@interface WMEAGLContext (Mac)

- (id)initWithOpenGLContext:(NSOpenGLContext *)context;

@property (nonatomic, strong, readonly) EAGLSharegroup *sharegroup;
@property (nonatomic, strong, readonly) NSOpenGLContext *openGLContext;

//TODO: figure out another way to handle this
- (void)setViewport:(CGRect)desiredViewport;

//We had some state mutated behind our back. Deal with it.
- (void)wm__assumeBoundFramebufferHack;

@end
#endif
