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
@property (nonatomic, copy) NSString *vertexShader;
@property (nonatomic, copy) NSString *pixelShader;

@end

NSString *const WMShaderAttributeNamePosition = @"position";
NSString *const WMShaderAttributeNameColor = @"color";
NSString *const WMShaderAttributeNameNormal = @"normal";
NSString *const WMShaderAttributeNameTexCoord0 = @"texCoord0";
NSString *const WMShaderAttributeNameTexCoord1 = @"texCoord1";

NSString *const WMShaderAttributeTypePosition = @"vec4";
NSString *const WMShaderAttributeTypeColor = @"vec4";
NSString *const WMShaderAttributeTypeNormal = @"vec3";
NSString *const WMShaderAttributeTypeTexCoord0 = @"vec2";
NSString *const WMShaderAttributeTypeTexCoord1 = @"vec2";


@implementation WMShader

@synthesize attributeMask;
@synthesize uniformNames;
@synthesize vertexShader;
@synthesize pixelShader;
@synthesize program;


- (id)initWithResourceName:(NSString *)inResourceName properties:(NSDictionary *)inProperties assetManager:(WMAssetManager *)inAssetManager;
{
	self = [super initWithResourceName:inResourceName properties:inProperties assetManager:inAssetManager];
	if (self == nil) return self; 
	
	uniformLocations = [[NSMutableDictionary alloc] init];

	self.uniformNames = [inProperties objectForKey:@"uniformNames"];
	
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

+ (NSString *)nameForShaderAttribute:(NSUInteger)shaderAttribute;
{
	NSString *const WMShaderAttributeNames[] = {
		WMShaderAttributeNamePosition, 
		WMShaderAttributeNameNormal, 
		WMShaderAttributeNameColor, 
		WMShaderAttributeNameTexCoord0,
		WMShaderAttributeNameTexCoord1};
	return WMShaderAttributeNames[shaderAttribute];
}

+ (NSString *)typeForShaderAttribute:(NSUInteger)shaderAttribute;
{
	NSString *const WMShaderAttributeTypes[] = {
		WMShaderAttributeTypePosition, 
		WMShaderAttributeTypeNormal, 
		WMShaderAttributeTypeColor, 
		WMShaderAttributeTypeTexCoord0,
		WMShaderAttributeTypeTexCoord1};
	return WMShaderAttributeTypes[shaderAttribute];
}


- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;
{
	if ([EAGLContext currentContext].API == kEAGLRenderingAPIOpenGLES2) {		

		NSString *vertexShaderPath = [resourceName stringByAppendingPathExtension:@"vsh"];
		NSString *fragmentShaderPath = [resourceName stringByAppendingPathExtension:@"fsh"];
		
		[self requireAssetFileSynchronous:vertexShaderPath];
		[self requireAssetFileSynchronous:fragmentShaderPath];
		
		self.vertexShader = [NSString stringWithContentsOfFile:[[inBundle bundlePath] stringByAppendingPathComponent:vertexShaderPath] encoding:NSUTF8StringEncoding error:outError];
		if (!vertexShader) return NO;
		self.pixelShader = [NSString stringWithContentsOfFile:[[inBundle bundlePath] stringByAppendingPathComponent:fragmentShaderPath] encoding:NSUTF8StringEncoding error:outError];
		if (!pixelShader) return NO;
		
		isLoaded = [self loadShaders];
		
		GL_CHECK_ERROR;

		return isLoaded;
	} else {
		//TODO: OpenGL ES 1.0 support?
		return YES;
	}

}

- (void)setVertexShader:(NSString *)inVertexShader;
{
	if (vertexShader == inVertexShader) return;
	[vertexShader release];
	
	vertexShader = [inVertexShader copy];
}


- (void)setPixelShader:(NSString *)inPixelShader;
{
	if (pixelShader == inPixelShader) return;
	[pixelShader release];
	
	pixelShader = [inPixelShader copy];
}

- (BOOL)shaderText:(NSString *)inShaderText hasAttribute:(WMShaderAttribute)attribute;
{
	NSString *attributeName = [WMShader nameForShaderAttribute:attribute];
	NSString *type = [WMShader typeForShaderAttribute:attribute];
	ZAssert(attributeName, @"Could not find name for attribute!");
	ZAssert(type, @"Could not find type for attribute!");
	//attribute vec4 position;
	NSString *searchText = [NSString stringWithFormat:@"attribute %@ %@;", type, attributeName];
	return [inShaderText rangeOfString:searchText].location != NSNotFound;
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


- (GLuint)attribIndexForName:(NSString *)inName;
{
	NSArray *attribArray = [NSArray arrayWithObjects:WMShaderAttributeNamePosition, WMShaderAttributeNameColor, WMShaderAttributeNameNormal, WMShaderAttributeNameTexCoord0, WMShaderAttributeNameTexCoord1, nil];
	NSUInteger idx = [attribArray indexOfObject:inName];
	if (idx == NSNotFound) {
		NSLog(@"Illegal attribute name: %@", inName);
	}
	return idx;
}

- (BOOL)compileShaderSource:(NSString *)inSourceString toShader:(GLuint *)shader type:(GLenum)type;
{
    GLint status;
    const GLchar *source = [inSourceString UTF8String];
        
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
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
    if (status == 0)
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
	
	// Bind attribute locations.
	// This needs to be done prior to linking.
	attributeMask = 0;
	for (GLuint attribIndex = WMShaderAttributePosition; attribIndex < WMShaderAttributeCount; attribIndex++) {
		if ([self shaderText:vertexShader hasAttribute:attribIndex]) {
			//TODO: SECURITY: is utf-8 valid in GL attrib names
			
			//Bind name to number in OGL
			glBindAttribLocation(program, attribIndex, [[WMShader nameForShaderAttribute:attribIndex] UTF8String]);

			//set it in the mask
			attributeMask |= (1 << attribIndex);
		}
	}
	
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
	
	//Get uniform locations
	//TODO: switch to glGetActiveUniform to simplify manifest.plist
	for (NSString *uniformName in uniformNames) {
		int uniformLocation = glGetUniformLocation(program, [uniformName UTF8String]);
		[uniformLocations setObject:[NSNumber numberWithInt:uniformLocation] forKey:uniformName];
	}	
		
	// Release vertex and fragment shaders.
	if (vertShader)
		glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);
	
	return YES;
}


@end
