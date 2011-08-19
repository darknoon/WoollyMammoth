//
//  WMImageLoader.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/12/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class WMImagePort;
@class WMBundleDocument;
@interface WMImageLoader : WMPatch {
	WMImagePort *outputImage;
}

- (void)setImageWithImageFileURL:(NSURL *)inFileURL;

- (UIImage *)imageInDocument:(WMBundleDocument *)inDocument;

@property (nonatomic, copy) NSString *imageResource;

@end
