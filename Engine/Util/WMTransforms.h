

#ifdef __cplusplus
extern "C" {
#endif


GLKMatrix4 cameraMatrixForRect(CGRect rect);

GLKMatrix4 transformForRenderingInOrientation(UIImageOrientation outputOrientation, int renderWidth, int renderHeight);


#ifdef __cplusplus
}
#endif
