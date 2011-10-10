//The WMEAGLContext will assign us a vao. Do not mess with this outside of WMEAGLContext
@interface WMRenderObject (WMRenderObject_WMEAGLContext_Private)

@property (nonatomic) GLenum vertexArrayObject;

@property (nonatomic) BOOL vertexArrayObjectDirty;

- (void)createVAOIfNecessary;

@end