#if TARGET_OS_IPHONE

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <GLKit/GLKit.h>
#import "GLKMath_cpp.h"

#elif TARGET_OS_MAC

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import "EAGLContextMac.h"

#endif