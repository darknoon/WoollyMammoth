//
//  WMShader_WMEAGLContext_Private.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/10/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

@interface WMShader ()

//TODO: make these more private
@property (nonatomic, readonly) GLuint program;
- (int)attributeLocationForName:(NSString *)inName;
- (int)uniformLocationForName:(NSString *)inName;

//Then load the shaders, compile and link into a program in the current context
- (BOOL)loadShadersWithError:(NSError **)outError;

@property (nonatomic, copy) NSString *vertexShader;
@property (nonatomic, copy) NSString *fragmentShader;


@end