//
//  WMBundleDocument.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMBundleDocument.h"
#import "WMCompositionSerialization.h"
#import "WMRenderOutput.h"

#if TARGET_OS_IPHONE
#import <AssetsLibrary/AssetsLibrary.h>
#endif

NSString *WMBundleDocumentErrorDomain = @"com.darknoon.WMBundleDocument";

NSString *WMBundleDocumentRootPlistFileName = @"root.plist";
NSString *WMBundleDocumentPreviewFileName = @"preview.png";

NSString *WMBundleDocumentExtension = @"wmbundle";

//1 MB maximum
static NSUInteger maxPlistSize = 1 * 1024 * 1024;

@interface WMBundleDocument ()

@property (nonatomic, strong) WMPatch *rootPatch;

@end

@implementation WMBundleDocument {
	//Track all file handles open copying files
	NSMutableArray *_copyOperations;
}
#if TARGET_OS_IPHONE
@synthesize preview = _preview;
#endif

- (id)initWithFileURL:(NSURL *)url;
{
	self = [super initWithFileURL:url];
	if (!self) return nil;
	
	//Start off with a default patch. Can replace later by -loadFromContents..
	_rootPatch = [[WMPatch alloc] initWithPlistRepresentation:nil];
	_rootPatch.key = @"root";
	
	//Add a render output patch
	WMRenderOutput *output = [[WMRenderOutput alloc] initWithPlistRepresentation:nil];
	[_rootPatch addChild:output];
	
	_copyOperations = [[NSMutableArray alloc] init];
		
	return self;
}



- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError;
{
	if ([contents isKindOfClass:[NSFileWrapper class]]) {
		NSMutableDictionary *fileWrappers = [NSMutableDictionary dictionaryWithDictionary:[contents fileWrappers]];
		NSFileWrapper *rootPlistWrapper = [fileWrappers objectForKey:WMBundleDocumentRootPlistFileName];
		if ([rootPlistWrapper isRegularFile]) {
			
			NSData *plistData = [rootPlistWrapper regularFileContents];
			
			if (plistData.length < maxPlistSize) {
				
				NSError *error = nil;
				NSPropertyListFormat format;
				id plistObject = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:&format error:&error];
				
				if (plistObject && /*[plistObject isKindOfClass:[NSDictionary dictionary]]*/ [plistObject respondsToSelector:@selector(allKeys)]) {
					
					NSDictionary *tempUserDictionary = nil;
					error = nil;
					WMPatch *tempRootPatch = [WMCompositionSerialization patchWithPlistDictionary:plistObject compositionBasePath:[[self fileURL] path] userDictionary:&tempUserDictionary error:&error];
					if (tempRootPatch) {
						self.userDictionary = tempUserDictionary;
						self.rootPatch = tempRootPatch;
						
						//Resources = file wrappers - WMBundleDocumentRootPlistFileName
						[fileWrappers removeObjectForKey:WMBundleDocumentRootPlistFileName];
						[fileWrappers removeObjectForKey:WMBundleDocumentPreviewFileName];
						self.resourceWrappers = fileWrappers;
						
						//NSLog(@"Success in loadFromContents:ofType:error:");
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
			WMPatch *tempRootPatch = [WMCompositionSerialization patchWithPlistDictionary:plistObject compositionBasePath:[[self fileURL] path] userDictionary:&tempUserDictionary error:&error];
			if (tempRootPatch) {
				self.userDictionary = tempUserDictionary;
				self.rootPatch = tempRootPatch;
				//DLog(@"Success in loadFromContents:ofType:error:");
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
	//Serialize object graph
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
	
	//Write plist
	NSData *rootPlistData = [NSPropertyListSerialization dataWithPropertyList:rootPlist format:NSPropertyListBinaryFormat_v1_0 options:0 error:&plistError];
	
	if (rootPlistData) {
		NSFileWrapper *contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
		[contents addRegularFileWithContents:rootPlistData preferredFilename:WMBundleDocumentRootPlistFileName];
		
		//Add our resource files
		[self.resourceWrappers enumerateKeysAndObjectsUsingBlock:^(id _key, id _obj, BOOL *stop) {
			NSString *key = _key;
			NSFileWrapper *wrapper = _obj;
			wrapper.preferredFilename = key;
			[contents addFileWrapper:wrapper];
		}];
		
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

- (void)addResourceNamed:(NSString *)inResourceName fromURL:(NSURL *)inFileURL completion:(void (^)(NSError *error))completion;
{
	NSMutableDictionary *resourceWrappersMutable = [_resourceWrappers mutableCopy];
	
	NSError *error = nil;
	
	NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:inFileURL options:0 error:&error];
	
	if (wrapper) {
		wrapper.preferredFilename = inResourceName;
		[resourceWrappersMutable setObject:wrapper forKey:inResourceName];
	} else {
		NSLog(@"File wrapper error: %@", error);
		completion(error);
		return;
	}
	
	self.resourceWrappers = resourceWrappersMutable;
	completion(nil);
}

#if TARGET_OS_IPHONE
- (void)addResourceNamed:(NSString *)inResourceName fromAssetRepresentation:(ALAssetRepresentation *)inAsset completion:(void (^)(NSError *error))completion;
{
	//Write 1 MB at a time
	long long bufferSize = 1 * 1024 * 1024;
	long long assetSize = inAsset.size;
	
	//Copy data into our bundle
	NSURL *destinationURL = [[self fileURL] URLByAppendingPathComponent:inResourceName];
	
	//If the destination already exists, overwrite

	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	
	[self performAsynchronousFileAccessUsingBlock:^{
		
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path];
		
		BOOL ok = [[NSFileManager defaultManager] createFileAtPath:[destinationURL path] contents:nil attributes:nil];
		
		NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:[destinationURL path]];
		[file truncateFileAtOffset:0];
		
		//Don't get rid of the file until it's done
		[_copyOperations addObject:file];
		__weak WMBundleDocument *weakSelf = self;
		
		NSLog(@"Beginning file write to : %@ (%@) exists: %d create ok %d. Asset size %lld", file, destinationURL.path, exists, ok, assetSize);
		
		uint8_t *tempBuffer = malloc(bufferSize);	
		file.writeabilityHandler = ^(NSFileHandle *handle) {
			
			NSLog(@"Write handler called");
			
			long long offset = handle.offsetInFile;
			
			NSError *error = nil;
			NSUInteger readBytes = [inAsset getBytes:tempBuffer fromOffset:offset length:bufferSize error:&error];
			if (readBytes > 0) {
				[handle writeData:[NSData dataWithBytesNoCopy:tempBuffer length:bufferSize freeWhenDone:NO]];
				NSLog(@"Wrote some data. Offset: %lld size:%lld", offset, bufferSize);
			} else if (error) {
				free(tempBuffer);
				NSLog(@"error getting %lld bytes of data: %@ for buffer:%p", bufferSize, error, tempBuffer);
				completion(error);
				return;
			} else { //Read 0 bytes = EOF?
				offset = handle.offsetInFile;
				if (offset >= assetSize) {
					handle.writeabilityHandler = nil;
					free(tempBuffer);
					//Call back to main thread (whatever we were called on)
					dispatch_async(currentQueue, ^() {
						WMBundleDocument *self = weakSelf;
						//Success. Add this file to our assets
						[self->_copyOperations removeObject:handle];
						[self addResourceNamed:inResourceName fromURL:destinationURL completion:completion];
					});
				}

			}
			
		};
	}];
}

- (UIImage *)preview;
{
	//This has to be synchronous... Any way to get around that?
	if (!_preview) {
		_preview = [UIImage imageWithContentsOfFile:[[self.fileURL URLByAppendingPathComponent:WMBundleDocumentPreviewFileName] path]];
	}
	return _preview;
}

- (void)setPreview:(UIImage *)inPreview;
{
	if (_preview != inPreview) {
		_preview = inPreview;
		[self performAsynchronousFileAccessUsingBlock:^() {
			[UIImagePNGRepresentation(inPreview) writeToURL:[self.fileURL URLByAppendingPathComponent:WMBundleDocumentPreviewFileName] atomically:YES];
		}];
	}
}
#endif

- (void)removeResourceNamed:(NSString *)inResourceName;
{
	NSMutableDictionary *resourceWrappersMutable = [_resourceWrappers mutableCopy];
	
	[resourceWrappersMutable removeObjectForKey:inResourceName];
	//Delete file if exists
	
	self.resourceWrappers = resourceWrappersMutable;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted;
{
	NSLog(@"handle error: %@", error);
	[super handleError:error userInteractionPermitted:userInteractionPermitted];
}

@end
