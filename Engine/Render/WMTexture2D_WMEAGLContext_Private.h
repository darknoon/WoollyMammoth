
#import "WMEAGLContext.h"

@interface WMEAGLContext (WMTexture2D_WMEAGLContext_Private)

- (GLuint)bound2DTextureNameOnTextureUnit:(int)inTextureUnit;
- (void)setBound2DTextureName:(GLuint)inTextureName onTextureUnit:(int)inTextureUnit;

//Assigns a random texture unit for temporary use. No guarantees about texture binding outside the block
- (void)bind2DTextureNameForModification:(GLuint)inTextureName inBlock:(void (^)())blockWithGLOperations;

- (void)forgetTexture2DName:(GLuint)inTextureName;

//TODO: support cube maps

@end
