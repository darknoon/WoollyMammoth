

#ifdef __cplusplus
extern "C" {
#endif


GLKMatrix4 cameraMatrixForRect(CGRect rect);

#ifdef __OBJC__
#import <UIKit/UIKit.h>
GLKMatrix4 transformForRenderingInOrientation(UIImageOrientation outputOrientation, int renderWidth, int renderHeight);
#endif

#ifdef __cplusplus
}
#endif
