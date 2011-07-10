//
//  WMShader.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMShader.h"

@interface WMShader()
//Then load the shaders, compile and link into a program in the current context
- (BOOL)loadShaders;

@property (nonatomic, copy) NSArray *uniformNames;
@property (nonatomic, copy) NSArray *vertexAttributeNames;

@property (nonatomic, copy) NSString *vertexShader;
@property (nonatomic, copy) NSString *pixelShader;

@end

@implementation WMShader

@synthesize uniformNames;
@synthesize vertexAttributeNames;

@synthesize vertexShader;
@synthesize pixelShader;
@synthesize program;


- (id)initWithVertexShader:(NSString *)inVertexShader pixelShader:(NSString *)inPixelShader;
{
	self = [super init];
	if (self == nil) return self; 
	
	uniformLocations = [[NSMutableDictionary alloc] init];
	
	if ([EAGLContext currentContext].API == kEAGLRenderingAPIOpenGLES2) {		
				
		self.vertexShader = inVertexShader;
		self.pixelShader = inPixelShader;
		
		if (![self loadShaders]) {
			[self release];
			return nil;
		}
		
		GL_CHECK_ERROR;		
	} else {
		//TODO: OpenGL ES 1.0 support?
		NSLog(@"Can't create a shader in an ES1 context");
		[self release];
		return nil;
	}

	
	return self;
}


- (void)dealloc
{
	[vertexShader release];
	[pixelShader release];
	[uniformNames release];
	[uniformLocations release];

	if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }


	[super dealloc];
}

+ (NSString *)nameOfShaderType:(GLenum)inType;
{
	switch (inType) {
		case GL_FLOAT:
			return @"float";
		case GL_FLOAT_VEC2:
			return @"vec2";
		case GL_FLOAT_VEC3:
			return @"vec3";
		case GL_FLOAT_VEC4:
			return @"vec4";
		case GL_FLOAT_MAT2:
			return @"mat2";
		case GL_FLOAT_MAT3:
			return @"mat3";
		case GL_FLOAT_MAT4:
			return @"mat4";
		default:
			return @"<??>";
	}
}

- (int)uniformLocationForName:(NSString *)inName;
{
	NSNumber *unifiormLocationValue = [uniformLocations objectForKey:inName];
	if (!unifiormLocationValue) {
		//NSLog(@"Attempt to get uniform location for \"%@\", which was not specified in the shader.", inName);
		//TODO: is this a good error value?
		return -1;
	}
	return [unifiormLocationValue intValue];
}


- (int)attributeLocationForName:(NSString *)inName;
{
	NSUInteger i = [vertexAttributeNames indexOfObject:inName];
	if (i == NSNotFound) {
		return -1;
	} else {
		return (int)i;
	}
}

- (BOOL)compileShaderSource:(NSString *)inSourceString toShader:(GLuint *)shader type:(GLenum)type;
{
	NSMutableString *defsString = [NSMutableString stringWithCapacity:inSourceString.length + 100];

	NSDictionary *defs = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"1", (type == GL_VERTEX_SHADER) ? @"VERTEX_SHADER" : @"FRAGMENT_SHADER",
						  @"1", @"TARGET_OS_IPHONE", nil];
	[defs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[defsString appendFormat:@"#define %@ %@\n", key, obj];
	}];
	
	
    GLint status;
    const GLchar *glstrs[] = {[defsString UTF8String], [inSourceString UTF8String]};
	
    *shader = glCreateShader(type);
    glShaderSource(*shader, 2, glstrs, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}


- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);

    //TODO: use unified DEBUG macro
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram;
{
	if (!vertexShader || !pixelShader) {
		NSLog(@"Trying to render with missing shader!");
	}
	
    GLint logLength, status;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders;
{
	GLuint vertShader, fragShader;
	
	// Create shader program.
	program = glCreateProgram();
	
	// Create and compile vertex shader.
	if (![self compileShaderSource:vertexShader toShader:&vertShader type:GL_VERTEX_SHADER])
	{
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}	
	// Create and compile fragment shader.
	if (![self compileShaderSource:pixelShader toShader:&fragShader type:GL_FRAGMENT_SHADER]) {
		NSLog(@"Failed to compile fragment shader");
		return NO;
	}
	
	// Attach vertex shader to program.
	glAttachShader(program, vertShader);
	
	// Attach fragment shader to program.
	glAttachShader(program, fragShader);
	
	// Link program.
	if (![self linkProgram:program])
	{
		NSLog(@"Failed to link program: %d", program);
		
		if (vertShader) {
			glDeleteShader(vertShader);
			vertShader = 0;
		}
		if (fragShader) {
			glDeleteShader(fragShader);
			fragShader = 0;
		}
		if (program) {
			glDeleteProgram(program);
			program = 0;
		}
		
		return NO;
	}
	
	//Get attributes
	GLint activeAttributes = 0;
	glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &activeAttributes);
	NSMutableArray *attributeNamesMutable = [NSMutableArray arrayWithCapacity:activeAttributes];
	for (int i=0; i<activeAttributes; i++) {
		char nameBuf[1024];
		GLsizei length = 0;
		GLint attributeSize = 0;
		GLenum attributeType = 0;
		glGetActiveAttrib(program, i, sizeof(nameBuf), &length, &attributeSize, &attributeType, nameBuf);
		NSLog(@"gl attribute: %s type(%@) size:%d", nameBuf, [WMShader nameOfShaderType:attributeType], attributeSize);
		
		NSString *attributeName = [NSString stringWithCString:nameBuf encoding:NSASCIIStringEncoding];
		[attributeNamesMutable addObject:attributeName];
	}
	self.vertexAttributeNames = attributeNamesMutable;
	
	//Get uniform locations
	//TODO: switch to glGetActiveUniform to simplify manifest.plist
	GLint uniformCount = 0;
	glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &uniformCount);
	NSMutableArray *uniformNamesMutable = [NSMutableArray arrayWithCapacity:uniformCount];
	for (int i=0; i<uniformCount; i++) {
		char nameBuf[1024];
		GLsizei length = 0;
		GLint uniformSize = 0;
		GLenum uniformType = 0;
		glGetActiveUniform(program, i, sizeof(nameBuf), &length, &uniformSize, &uniformType, nameBuf);
		NSString *uniformName = [NSString stringWithCString:nameBuf encoding:NSASCIIStringEncoding];
		[uniformNamesMutable addObject:uniformName];
		
		int uniformLocation = glGetUniformLocation(program, nameBuf);
		[uniformLocations setObject:[NSNumber numberWithInt:uniformLocation] forKey:uniformName];
	}
	self.uniformNames = uniformNamesMutable;
	
	// Release vertex and fragment shaders.
	if (vertShader)
		glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);
	
	return YES;
}

@end
