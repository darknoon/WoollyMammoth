//
//  GLDefines.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/7/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#if DEBUG
#define DEBUG_OPENGL 1
#else
#define DEBUG_OPENGL 0
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#if DEBUG_OPENGL

#define GL_CHECK_ERROR \
{\
	GLenum _glError = glGetError();\
	if (_glError == GL_INVALID_ENUM) {\
		ALog(@"GL Error GL_INVALID_ENUM");\
	} else if (_glError == GL_INVALID_VALUE) {\
		ALog(@"GL Error GL_INVALID_VALUE");\
	} else if (_glError == GL_INVALID_OPERATION) {\
		ALog(@"GL Error GL_INVALID_OPERATION");\
	} else if (_glError == GL_OUT_OF_MEMORY) {\
		ALog(@"GL Error GL_OUT_OF_MEMORY");\
	}\
}

#else

#define GL_CHECK_ERROR
#endif
