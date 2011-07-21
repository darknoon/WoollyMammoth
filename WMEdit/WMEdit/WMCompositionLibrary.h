//
//  WMCompositionLibrary.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatch.h"

@interface WMCompositionLibrary : NSObject 
@property (nonatomic, readonly) NSArray *compositions;

+ (WMCompositionLibrary *)compositionLibrary;


// client calling this will save both image and plist next to each other, same name, diff extenstions: .plist .jpg

- (BOOL)saveComposition:(WMPatch *)root image:(UIImage *)image toURL:(NSURL *)inFileURL;
- (WMPatch *)compositionWithURL:(NSURL *)inURL;


- (NSString *)saveFolder;
- (NSString *)pathForResource:(NSString *)shortName;

- (UIImage *)imageForCompositionPath:(NSString *)fullCompositionPath;

@end

extern NSString *WM_PATH_EXTENSION;
