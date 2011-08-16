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


- (NSString *)documentsDirectory;
- (NSString *)pathForResource:(NSString *)shortName;
- (NSURL *)URLForResourceShortName:(NSString *)shortName;
- (NSString *)shortNameFromURL:(NSURL *)url;

- (BOOL)renameComposition:(NSURL *)oldFileURL to:(NSString *)newName;

- (UIImage *)imageForCompositionPath:(NSString *)fullCompositionPath;

@end

extern NSString *CompositionsChangedNotification;