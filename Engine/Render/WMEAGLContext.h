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

enum {
	//Cull all back faces (not facing the camera)
	DNGLCullFaceBack = 1 << 0,
	//Cull all back faces 
	DNGLCullFaceFront = 1 << 1,
};
typedef int DNGLCullFaceMask;

@class WMFramebuffer;
@class WMTexture2D;
@class WMRenderObject;
@class WMVertexArrayObject;
@class CAEAGLLayer;

@interface WMEAGLContext : EAGLContext

//Some objects should have gl state backing, some not
//ie WMStructuredBuffer only has gl backing when actually being used to render, transparent to the user
//ie WMRenderObject only has a VAO backing when actually going to be rendered to the screen

/////// State object factory methods ///////

//Create a framebuffer to draw out to screen
#if 0
- (WMFramebuffer *)newFramebufferFromLayer:(CAEAGLLayer *)inLayer;

//Texture must be associated with this GL context
- (WMFramebuffer *)newFramebufferFromTexture:(WMTexture2D *)inTexture;

//Creates a new texture.
//Binding of textures is controlled exclusively by the render object system and glsl uniforms
- (WMTexture2D *)newTexture;

//Creates a new VAO
//Binding of VAOs is controlled
- (WMVertexArrayObject *)newVertexArrayObject;

//Create a new shader
- (WMShader *)newShaderWithVertexProgram:(NSString *)inVertexProgram fragmentProgram:(NSString *)inFragmentProgram error:(NSError **)outError;
#endif

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

@end
