
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

extern void CGContextAddRoundRect(CGContextRef context, CGRect rect, float radius);

extern void CGPathAddRoundRect (CGMutablePathRef path, const CGAffineTransform *m, CGRect rect, float radius);