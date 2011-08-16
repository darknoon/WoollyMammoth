//
//  WMBundleDocument.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatch.h"
#import "WMCompositionSerialization.h"

//File extension for Woolly Mammoth bundles
extern NSString *WMBundleDocumentExtension;

enum WMBundleDocumentRError {
	WMBundleDocumentErrorRootDataSize = -14,
	WMBundleDocumentErrorRootPlistInvalid = -15,	
	WMBundleDocumentErrorRootPatchReadError = -16,	
	WMBundleDocumentErrorRootPatchWriteError = -1001,	
};

extern NSString *WMBundleDocumentErrorDomain;

#define USE_UIDOCUMENT 0

//UIDocument is fucking broken. So, I'm subclassing object instead for now.
#if USE_UIDOCUMENT
@interface WMBundleDocument : UIDocument
#else
@interface WMBundleDocument : NSObject

@property(readonly) NSURL *fileURL;
@property(readonly, copy) NSString *localizedName;  // The default implementation derives the name from the URL. Subclasses may override to provide a custom name for presentation to the user, such as in error strings.
@property(readonly, copy) NSString *fileType;       // The file's UTI. Derived from the fileURL by default.

@property(readonly) UIDocumentState documentState;

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError;
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError;

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted;

- (void)saveToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^)(BOOL success))completionHandler;
- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError;

#endif




@property (nonatomic, retain, readonly) WMPatch *rootPatch;
@property (nonatomic, copy) NSDictionary *userDictionary;

@end
