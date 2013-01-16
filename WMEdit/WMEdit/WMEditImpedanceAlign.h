

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

#define WMPlatformViewClass UIView
#define WMPlatformImageViewClass UIImageView
#define WMPlatformImage UIImage
#define WMPlatformScrollView UIScrollView
#define WMPlatformLabel UILabel

#else

#import <AppKit/AppKit.h>

#define WMPlatformViewClass NSView
#define WMPlatformImageViewClass NSView
#define WMPlatformImage NSImage
#define WMPlatformScrollView NSScrollView
#define UIEdgeInsets NSEdgeInsets
#define WMPlatformLabel NSTextField

#endif

