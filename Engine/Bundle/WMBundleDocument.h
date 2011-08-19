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
#import "DNDocument.h"

//File extension for Woolly Mammoth bundles
extern NSString *WMBundleDocumentExtension;

enum WMBundleDocumentError {
	WMBundleDocumentErrorRootDataSize = -14,
	WMBundleDocumentErrorRootPlistInvalid = -15,	
	WMBundleDocumentErrorRootPatchReadError = -16,	
	WMBundleDocumentErrorRootPatchWriteError = -1001,	
};

extern NSString *WMBundleDocumentErrorDomain;

@class ALAssetRepresentation;
@interface WMBundleDocument : DNDocument

@property (nonatomic, retain, readonly) WMPatch *rootPatch;
@property (nonatomic, copy) NSDictionary *userDictionary;

//Dictionary of name => file wrapper representing the resources for this bundle
@property (nonatomic, copy) NSDictionary *resourceWrappers;

//Resource name should include the file path extension
- (void)addResourceNamed:(NSString *)inResourceName fromURL:(NSURL *)inFileURL completion:(void (^)(NSError *error))completion;
- (void)addResourceNamed:(NSString *)inResourceName fromAssetRepresentation:(ALAssetRepresentation *)inAsset completion:(void (^)(NSError *error))completion;

- (void)removeResourceNamed:(NSString *)inResourceName;


@end
