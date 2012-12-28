#if TARGET_OS_IPHONE

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <GLKit/GLKit.h>

#elif TARGET_OS_MAC

#import <OpenGL/OpenGL.h>
#import <AppKit/AppKit.h>

#if WM_OGL_VERSION == 3

#warning OpenGL core profile is currently unsupported due to shader sharing with iOS.
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#elif WM_OGL_VERSION == 2

#import <OpenGL/CGLContext.h>
//#import <OpenGL/gl.h>
//#import <OpenGL/glext.h>
#endif

#endif

