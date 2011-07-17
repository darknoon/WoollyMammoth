//
//  WMCompositionLibrary.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WMRootPatch;

@interface WMCompositionLibrary : NSObject 
@property (nonatomic, retain) NSMutableArray *compositions;

+ (WMCompositionLibrary *)compositionLibrary;


// client calling this will save both image and plist next to each other, same name, diff extenstions: .plist .jpg

- (BOOL)saveComposition:(WMRootPatch *)root image:(UIImage *)image;
- (WMRootPatch *)compositionWithPath:(NSString *)fullPath;


- (NSString *)saveFolder;
- (NSString *)pathForResource:(NSString *)shortName;
- (BOOL)saveComposition:(id)thing;

- (UIImage *)imageForCompositionPath:(NSString *)fullCompositionPath;
- (NSString *)pathForThumbOfComposition:(NSString *)fullCompositionPath;

@end

extern NSString *WM_PATH_EXTENSION;
