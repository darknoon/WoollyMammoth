//
//  WMCompositionLibrary.h
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WMCompositionLibrary : NSObject 
@property (nonatomic, retain) NSMutableArray *compositions;

+ (WMCompositionLibrary *)compositionLibrary;

- (NSString *)saveFolder;
- (NSString *)pathForResource:(NSString *)shortName;
- (BOOL)saveComposition:(id)thing;
- (id)compositionWithPath:(NSString *)fullPath;

@end

extern NSString *WM_PATH_EXTENSION;
