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

- (NSURL *)URLForResourceShortName:(NSString *)shortName;
- (NSString *)shortNameFromURL:(NSURL *)url;

- (UIImage *)imageForCompositionPath:(NSURL *)fullComposition;

- (void)addCompositionURL:(NSURL *)inFileURL;
- (void)removeCompositionURL:(NSURL *)inFileURL;

@end

extern NSString *CompositionsChangedNotification;