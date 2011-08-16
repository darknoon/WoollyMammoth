//
//  WMSetShader.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMSetShader.h"

#import "WMShader.h"

#import "WMRenderObject.h"

NSString *WMVertexShaderKey = @"vertexShader";
NSString *WMFragmentShaderKey = @"fragmentShader";

@interface WMSetShader ()
@property (nonatomic) BOOL shaderIsCompiled;
@property (nonatomic, copy) NSString *shaderCompileLog;
@end

@implementation WMSetShader
@synthesize vertexShader;
@synthesize fragmentShader;
@synthesize shaderIsCompiled;
@synthesize shaderCompileLog;

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

+ (NSString *)humanReadableTitle {
    return @"Set Shader";
}

+ (void)load;
{
	@autoreleasepool {
		[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass(self)]];
	}
}

- (id)plistState;
{
	NSMutableDictionary *d = [[super plistState] mutableCopy];
	
	if (self.vertexShader) [d setObject:self.vertexShader forKey:WMVertexShaderKey];
	if (self.fragmentShader) [d setObject:self.fragmentShader forKey:WMFragmentShaderKey];
	
	return d;
}

- (BOOL)setPlistState:(id)inPlist;
{
	//Load saved shaders
	self.vertexShader = [inPlist objectForKey:WMVertexShaderKey];
	self.fragmentShader = [inPlist objectForKey:WMFragmentShaderKey];
	
	//Load default shaders
	NSError *defaultShaderError = nil;
	if (self.vertexShader.length == 0) {
		self.vertexShader = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WMDefaultShader" withExtension:@"vsh"] encoding:NSASCIIStringEncoding error:&defaultShaderError];
		if (defaultShaderError) {
			NSLog(@"Error loading default vertex shader: %@", defaultShaderError);
		}
	}
	if (self.fragmentShader.length == 0) {
		self.fragmentShader = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WMDefaultShader" withExtension:@"fsh"] encoding:NSASCIIStringEncoding error:&defaultShaderError];
		if (defaultShaderError) {
			NSLog(@"Error loading default fragment shader: %@", defaultShaderError);
		}
	}
	
	return [super setPlistState:inPlist];
}

- (void)setVertexShader:(NSString *)inVertexShader;
{
	if (vertexShader != inVertexShader && ![vertexShader isEqualToString:inVertexShader]) {
		vertexShader = [inVertexShader copy];
		shaderDirty = YES;
	}
}

- (void)setFragmentShader:(NSString *)inFragmentShader;
{
	if (fragmentShader != inFragmentShader && ![fragmentShader isEqualToString:inFragmentShader]) {
		fragmentShader = [inFragmentShader copy];
		shaderDirty = YES;
	}
}

- (void)recreateInputPorts;
{
	//Remove old input ports
	for (WMPort *port in self.inputPorts) {
		if (port != inputObject) {
			[self removeInputPort:port];
		}
	}
	//Add new input ports
	for (NSString *uniformName in shader.uniformNames) {
		WMPort *uniformPort = nil;
		GLenum type = [shader uniformTypeForName:uniformName];
		if (type == GL_FLOAT) {
			uniformPort = [WMNumberPort portWithKey:uniformName];
		} else if (type == GL_FLOAT_VEC2) {
			uniformPort = [WMVector2Port portWithKey:uniformName];
		} else if (type == GL_FLOAT_VEC3) {
			uniformPort = [WMVector3Port portWithKey:uniformName];
		} else if (type == GL_FLOAT_VEC4) {
			uniformPort = [WMVector4Port portWithKey:uniformName];
		} else if (type == GL_SAMPLER_2D) {
			uniformPort = [WMImagePort portWithKey:uniformName];
		}
		if (uniformPort) {
			[self addInputPort:uniformPort];
		} else {
			NSLog(@"Couldn't make uniform port for %@ %@", [WMShader nameOfShaderType:type], uniformName);
		}
	}
	
}

//Can only execute this in a gl state
- (void)compileShaderIfNecessary;
{
	if (shaderDirty) {
		NSError *error = nil;
		shader = [[WMShader alloc] initWithVertexShader:self.vertexShader fragmentShader:self.fragmentShader error:&error];
		if (error) {
			self.shaderCompileLog = [[error userInfo] objectForKey:NSLocalizedDescriptionKey];
		} else {
			self.shaderCompileLog = nil;
		}
		self.shaderIsCompiled = shader != nil;
		
		if (shader) {
			[self recreateInputPorts];
		}
		
		shaderDirty = NO;
	}
}


- (BOOL)setup:(WMEAGLContext *)context;
{
	//Try to compile here if we can
	[self compileShaderIfNecessary];
	return YES;
}


- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	[self compileShaderIfNecessary];
	
	WMRenderObject *object = inputObject.object;
	if (shader) {
		object.shader = shader;
	}
	outputObject.object = object;
	
	//Set shader uniforms from our input ports
	for (WMPort *port in inputPorts) {
		if (port != inputObject) {
			id value = nil;
			if ([port isKindOfClass:[WMNumberPort class]]) {
				value = [(WMNumberPort *)port stateValue];
			} else if ([port isKindOfClass:[WMVectorPort class]]) {
				value = [(WMVectorPort *)port objectValue];
			} else if ([port isKindOfClass:[WMImagePort class]]) {
				value = [(WMImagePort *)port image];
			}
			
			if (value) {
				[object setValue:value forUniformWithName:port.key];
			}
		}
	}
	
	return YES;
}


@end
