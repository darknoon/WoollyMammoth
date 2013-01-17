//
//  WMCompositionLibrary.h
//  WMEdit
//
//  Created by Andrew Pouliot on 1/16/13.
//  Copyright 2013 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMCompositionLibrary : NSObject 

+ (instancetype)sharedLibrary;

@property (nonatomic, readonly) NSArray *compositions;

//Re-reads the directory and sends a changed notification if relevant.
//Yes this is a horrible hack :P
- (void)refresh;

- (NSURL *)untitledDocumentURL;

@end

extern NSString *WMCompositionLibraryCompositionsChangedNotification;