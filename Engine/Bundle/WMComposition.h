//
//  WMComposition.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif


#import "WMPatch.h"
#import "WMCompositionSerialization.h"

//File extension for Woolly Mammoth bundles
extern NSString *WMBundleDocumentExtension;

extern NSString *WMBundleDocumentRootPlistFileName;

enum WMBundleDocumentError {
	WMBundleDocumentErrorRootDataSize = -14,
	WMBundleDocumentErrorRootPlistInvalid = -15,	
	WMBundleDocumentErrorRootPatchReadError = -16,	
	WMBundleDocumentErrorRootPatchWriteError = -1001,	
};

extern NSString *WMBundleDocumentErrorDomain;

@class ALAssetRepresentation;

@interface WMComposition : NSObject

- (id)initWithFileURL:(NSURL *)url error:(NSError **)outError;
- (id)initWithFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

- (NSFileWrapper *)fileWrapperRepresentationWithError:(NSError **)outError;

@property (readonly) NSURL *fileURL;

@property (nonatomic, strong, readonly) WMPatch *rootPatch;
@property (nonatomic, copy) NSDictionary *userDictionary;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIImage *preview;
#endif

//Dictionary of name => file wrapper representing the resources for this bundle
@property (nonatomic, copy) NSDictionary *resourceWrappers;

//Resource name should include the file path extension
- (void)addResourceNamed:(NSString *)inResourceName fromURL:(NSURL *)inFileURL completion:(void (^)(NSError *error))completion;

#if TARGET_OS_IPHONE
- (void)addResourceNamed:(NSString *)inResourceName fromAssetRepresentation:(ALAssetRepresentation *)inAsset completion:(void (^)(NSError *error))completion;
#endif

- (void)removeResourceNamed:(NSString *)inResourceName;


@end
