//
//  WMShader.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMShader.h"
#import "WMEAGLContext.h"

NSString *WMShaderErrorDomain = @"com.darknoon.WMShader";

@interface WMShader()
//Then load the shaders, compile and link into a program in the current context
- (BOOL)loadShadersWithError:(NSError **)outError;

@property (nonatomic, copy) NSArray *uniformNames;
@property (nonatomic, copy) NSArray *vertexAttributeNames;

@property (nonatomic, copy) NSArray *uniformTypes;
@property (nonatomic, copy) NSArray *vertexAttributeTypes;

@property (nonatomic, copy) NSString *vertexShader;
@property (nonatomic, copy) NSString *fragmentShader;

@end

@implementation WMShader {
	NSMutableDictionary *uniformLocations;
	__weak EAGLContext *owningContext;
}


@synthesize uniformNames;
@synthesize uniformTypes;
@synthesize vertexAttributeNames;
@synthesize vertexAttributeTypes;

@synthesize vertexShader;
@synthesize fragmentShader;
@synthesize program;


- (id)initWithVertexShader:(NSString *)inVertexShader fragmentShader:(NSString *)inPixelShader error:(NSError **)outError;
{
	self = [super init];
	if (self == nil) return self; 
	
	uniformLocations = [[NSMutableDictionary alloc] init];
	
	owningContext = [EAGLContext currentContext];
	
	self.vertexShader = inVertexShader;
	self.fragmentShader = inPixelShader;
	
	if (![self loadShadersWithError:outError]) {
		return nil;
	}
	
	
	//TODO: roll this check into the out error!
	GL_CHECK_ERROR;		
	
	
	return self;
}


- (void)dealloc
{
	if (owningContext) {
		[EAGLContext setCurrentContext:owningContext];
		if (program)
		{
			glDeleteProgram(program);
			program = 0;
		}
	}
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


- (GLenum)uniformTypeForName:(NSString *)inUniformName;
{
	NSNumber *uniformTypeNumber = [uniformTypes objectAtIndex:[uniformNames indexOfObject:inUniformName]];
	return uniformTypeNumber ? [uniformTypeNumber unsignedIntValue] : 0;
}

- (GLenum)vertexTypeForName:(NSString *)inAttributeName;
{
	NSNumber *vertexTypeNumber = [vertexAttributeTypes objectAtIndex:[vertexAttributeNames indexOfObject:inAttributeName]];
	return vertexTypeNumber ? [vertexTypeNumber unsignedIntValue] : 0;
}

- (BOOL)compileShaderSource:(NSString *)inSourceString toShader:(GLuint *)shader type:(GLenum)type error:(NSError **)outError;
{
	if (!inSourceString) inSourceString = @"";
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
        
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
		//ERROR
		GLint logLength;
		glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
		if (logLength > 0)
		{
			GLchar *log = (GLchar *)malloc(logLength);
			glGetShaderInfoLog(*shader, logLength, &logLength, log);
			
			if (outError) {
				NSString *shaderErrorString = [NSString stringWithFormat:NSLocalizedString(@"Error compiling shader: %@", nil), [NSString stringWithCString:log encoding:NSASCIIStringEncoding]];
				NSError *error = [NSError errorWithDomain:WMShaderErrorDomain
													 code:WMShaderErrorCompileError
												 userInfo:[NSDictionary dictionaryWithObject:shaderErrorString forKey:NSLocalizedDescriptionKey]];
				*outError = error;
			}
			NSLog(@"Shader compile log:\n%s", log);
			
			free(log);
		}

        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}


- (BOOL)linkProgram:(GLuint)prog error:(NSError **)outError
{
    GLint status;
    
    glLinkProgram(prog);
	
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0) {
		//If there is an error, get the status
		
		GLint logLength;
		glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
		if (logLength > 0)
		{
			GLchar *log = (GLchar *)malloc(logLength);
			glGetProgramInfoLog(prog, logLength, &logLength, log);
			if (outError) {
				NSString *shaderLinkErrorString = [NSString stringWithFormat:NSLocalizedString(@"Error linking shader: %@", nil), [NSString stringWithCString:log encoding:NSASCIIStringEncoding]];
				*outError = [NSError errorWithDomain:WMShaderErrorDomain
												code:WMShaderErrorLinkError
											userInfo:[NSDictionary dictionaryWithObject:shaderLinkErrorString forKey:NSLocalizedDescriptionKey]];

			}
			NSLog(@"Program link log:\n%s", log);
			free(log);
		}
		
        return FALSE;
	}
    
    return TRUE;
}

- (BOOL)validateProgram;
{
	if (!vertexShader || !fragmentShader) {
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

- (BOOL)loadShadersWithError:(NSError **)outError;
{
	GLuint vertShader, fragShader;
	
	// Create shader program.
	program = glCreateProgram();
	
	NSError *error = nil;
	
	// Create and compile vertex shader.
	if (![self compileShaderSource:vertexShader toShader:&vertShader type:GL_VERTEX_SHADER error:&error])
	{
		NSLog(@"Failed to compile vertex shader");
		if (outError) *outError = error;
		return NO;
	}	
	// Create and compile fragment shader.
	if (![self compileShaderSource:fragmentShader toShader:&fragShader type:GL_FRAGMENT_SHADER error:&error]) {
		NSLog(@"Failed to compile fragment shader");
		if (outError) *outError = error;
		return NO;
	}
	
	// Attach vertex shader to program.
	glAttachShader(program, vertShader);
	
	// Attach fragment shader to program.
	glAttachShader(program, fragShader);
	
	// Link program.
	if (![self linkProgram:program error:&error])
	{
		NSLog(@"Failed to link program: %d", program);
		if (outError) *outError = error;

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
	
	//TODO: can we have an error in these methods?
	
	//Get attributes
	GLint activeAttributes = 0;
	glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &activeAttributes);
	NSMutableArray *attributeNamesMutable = [NSMutableArray arrayWithCapacity:activeAttributes];
	NSMutableArray *attributeTypesMutable = [NSMutableArray arrayWithCapacity:activeAttributes];
	for (int i=0; i<activeAttributes; i++) {
		char nameBuf[1024];
		GLsizei nameLength = 0;
		GLint attributeSize = 0;
		GLenum attributeType = 0;
		glGetActiveAttrib(program, i, sizeof(nameBuf), &nameLength, &attributeSize, &attributeType, nameBuf);
	//	NSLog(@"gl attribute: %s type(%@) size:%d", nameBuf, [WMShader nameOfShaderType:attributeType], attributeSize);
		
		NSString *attributeName = [NSString stringWithCString:nameBuf encoding:NSASCIIStringEncoding];
		[attributeNamesMutable addObject:attributeName];
		[attributeTypesMutable addObject:[NSNumber numberWithUnsignedInt:attributeType]];
	}
	self.vertexAttributeNames = attributeNamesMutable;
	self.vertexAttributeTypes = attributeTypesMutable;
	
	//Get uniform locations
	GLint uniformCount = 0;
	glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &uniformCount);
	NSMutableArray *uniformNamesMutable = [NSMutableArray arrayWithCapacity:uniformCount];
	NSMutableArray *uniformTypesMutable = [NSMutableArray arrayWithCapacity:uniformCount];
	for (int i=0; i<uniformCount; i++) {
		char nameBuf[1024];
		GLsizei nameLength = 0;
		GLint uniformSize = 0;
		GLenum uniformType = 0;
		glGetActiveUniform(program, i, sizeof(nameBuf), &nameLength, &uniformSize, &uniformType, nameBuf);
		NSString *uniformName = [NSString stringWithCString:nameBuf encoding:NSASCIIStringEncoding];
		[uniformNamesMutable addObject:uniformName];
		
		int uniformLocation = glGetUniformLocation(program, nameBuf);
		[uniformLocations setObject:[NSNumber numberWithInt:uniformLocation] forKey:uniformName];
		[uniformTypesMutable addObject:[NSNumber numberWithUnsignedInt:uniformType]];
	}
	self.uniformNames = uniformNamesMutable;
	self.uniformTypes = uniformTypesMutable;
	
	// Release vertex and fragment shaders.
	if (vertShader)
		glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);
	
	return YES;
}

@end
