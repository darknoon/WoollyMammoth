

#ifdef __cplusplus
extern "C" {
#endif


GLKMatrix4 cameraMatrixForRect(CGRect rect);

#if defined(__OBJC__) && TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import "WMCompatibilityMac.h"
#endif

	GLKMatrix4 transformForRenderingInOrientation(UIImageOrientation outputOrientation, int renderWidth, int renderHeight);
	
	
#ifdef __cplusplus
}
#endif
