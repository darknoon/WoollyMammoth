//The WMEAGLContext will assign us a vao. Do not mess with this outside of WMEAGLContext
@interface WMRenderObject (WMRenderObject_WMEAGLContext_Private)

- (void)createVAOIfNecessary;

@property (nonatomic, strong) WMVertexArrayObject *vertexArrayObject;
@property (nonatomic) BOOL vertexArrayObjectDirty;

@end