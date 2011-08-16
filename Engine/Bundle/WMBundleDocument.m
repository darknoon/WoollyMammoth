//
//  WMBundleDocument.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMBundleDocument.h"
#import "WMCompositionSerialization.h"

NSString *WMBundleDocumentErrorDomain = @"com.darknoon.WMBundleDocument";

NSString *WMBundleDocumentRootPlistFileName = @"root.plist";

NSString *WMBundleDocumentExtension = @"wmbundle";

//1 MB maximum
static NSUInteger maxPlistSize = 1 * 1024 * 1024;

@interface WMBundleDocument ()

@property (nonatomic, retain) WMPatch *rootPatch;

@end

@implementation WMBundleDocument
@synthesize rootPatch;
@synthesize userDictionary;


- (id)initWithFileURL:(NSURL *)url;
{
	self = [super initWithFileURL:url];
	if (!self) return nil;
	
	//Start off with a default patch. Can replace later by -loadFromContents..
	rootPatch = [[WMPatch alloc] initWithPlistRepresentation:nil];
	rootPatch.key = @"root";
		
	return self;
}

- (void)dealloc {
    [rootPatch release];
	[userDictionary release];
	
    [super dealloc];
}


- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError;
{
	if ([contents isKindOfClass:[NSFileWrapper class]]) {
		NSDictionary *fileWrappers = [contents fileWrappers];
		NSFileWrapper *bundleWrapper = [fileWrappers objectForKey:WMBundleDocumentRootPlistFileName];
		if ([bundleWrapper isRegularFile]) {
			
			NSData *plistData = [bundleWrapper regularFileContents];
			
			if (plistData.length < maxPlistSize) {
				
				NSError *error = nil;
				NSPropertyListFormat format;
				id plistObject = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:&format error:&error];
				
				if (plistObject && /*[plistObject isKindOfClass:[NSDictionary dictionary]]*/ [plistObject respondsToSelector:@selector(allKeys)]) {
					
					NSDictionary *tempUserDictionary = nil;
					error = nil;
					WMPatch *tempRootPatch = [WMCompositionSerialization patchWithPlistDictionary:plistObject compositionBasePath:[[self fileURL] path] userDictionary:&userDictionary error:&error];
					if (tempRootPatch) {
						self.userDictionary = tempUserDictionary;
						self.rootPatch = tempRootPatch;
						NSLog(@"Success in loadFromContents:ofType:error:");
						return YES;
					} else {
						if (outError) {
							*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
															code:WMBundleDocumentErrorRootPatchReadError
														userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not read the WMPatch provided.", nil)
																							 forKey:NSLocalizedDescriptionKey]];
						}
						return NO;
					}
					
				} else {
					//plist read error
					if (outError) {
						NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
						if (error) {
							[errorUserInfo setObject:error forKey:NSUnderlyingErrorKey];
						}
						[errorUserInfo setObject:NSLocalizedString(@"Could not read plist.", nil) forKey:NSLocalizedDescriptionKey];
						
						*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
														code:WMBundleDocumentErrorRootPlistInvalid
													userInfo:errorUserInfo];
					}
					return NO;

				}
			} else {
				if (outError) {
					*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
													code:WMBundleDocumentErrorRootDataSize
												userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Node graph exceeds maximum size.", nil)
																					 forKey:NSLocalizedDescriptionKey]];
				}
				return NO;
			}
			return YES;
		} else {
			//Bundle file was a directory or link
			if (outError) {
				*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
												code:WMBundleDocumentErrorRootPlistInvalid
											userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Root plist not found or invalid. Expected to find a file named \"root.plist\" in the bundle.", nil)
																				 forKey:NSLocalizedDescriptionKey]];
			}
			return NO;
		}
	} else if ([contents isKindOfClass:[NSData class]]) {
		NSError *error = nil;
		NSPropertyListFormat format;
		id plistObject = [NSPropertyListSerialization propertyListWithData:contents options:0 format:&format error:&error];
		
		if (plistObject && /*[plistObject isKindOfClass:[NSDictionary dictionary]]*/ [plistObject respondsToSelector:@selector(allKeys)]) {
			
			NSDictionary *tempUserDictionary = nil;
			error = nil;
			WMPatch *tempRootPatch = [WMCompositionSerialization patchWithPlistDictionary:plistObject compositionBasePath:[[self fileURL] path] userDictionary:&userDictionary error:&error];
			if (tempRootPatch) {
				self.userDictionary = tempUserDictionary;
				self.rootPatch = tempRootPatch;
				NSLog(@"Success in loadFromContents:ofType:error:");
				return YES;
			} else {
				if (outError) {
					*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
													code:WMBundleDocumentErrorRootPatchReadError
												userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not read the WMPatch provided.", nil)
																					 forKey:NSLocalizedDescriptionKey]];
				}
				return NO;
			}
			
		} else {
			//plist read error
			if (outError) {
				NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
				if (error) {
					[errorUserInfo setObject:error forKey:NSUnderlyingErrorKey];
				}
				[errorUserInfo setObject:NSLocalizedString(@"Could not read plist.", nil) forKey:NSLocalizedDescriptionKey];
				
				*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
												code:WMBundleDocumentErrorRootPlistInvalid
											userInfo:errorUserInfo];
			}
			return NO;
		}
	} else {
		return NO;
	}
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError;
{
	NSError *plistError = nil;
	NSDictionary *rootPlist = [WMCompositionSerialization plistDictionaryWithRootPatch:self.rootPatch userDictionary:self.userDictionary error:&plistError];
	if (!rootPlist) {
		if (outError) {
			*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
											code:WMBundleDocumentErrorRootPatchWriteError
										userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not serialize the WMPatch provided.", nil)
																			 forKey:NSLocalizedDescriptionKey]];
		}
	}
	NSData *rootPlistData = [NSPropertyListSerialization dataWithPropertyList:rootPlist format:NSPropertyListBinaryFormat_v1_0 options:0 error:&plistError];
	
	if (rootPlistData) {
		NSFileWrapper *contents = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil] autorelease];
		[contents addRegularFileWithContents:rootPlistData preferredFilename:WMBundleDocumentRootPlistFileName];
		return contents;
	} else {
		if (outError) {
			*outError = [NSError errorWithDomain:WMBundleDocumentErrorDomain
											code:WMBundleDocumentErrorRootPatchWriteError
										userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not convert the WMPatch serialization into a plist.", nil)
																			 forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted;
{
	NSLog(@"handle error: %@", error);
	[super handleError:error userInteractionPermitted:userInteractionPermitted];
}

@end
