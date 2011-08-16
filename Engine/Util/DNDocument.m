//
//  DNDocument.m
//  WMViewer
//
//  Created by Andrew Pouliot on 8/16/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "DNDocument.h"

@implementation DNDocument

#if !USE_UIDOCUMENT
@synthesize fileURL;
@synthesize fileType;
@synthesize localizedName;
@synthesize documentState;
#endif

- (id)initWithFileURL:(NSURL *)url;
{
#if USE_UIDOCUMENT
	self = [super initWithFileURL:url];
	if (!self) return nil;
#else
	self = [super init];
	if (!self) return nil;
	fileURL = [url retain];
	documentState = UIDocumentStateClosed;
#endif
		
	return self;
}

#if !USE_UIDOCUMENT

- (NSString *)fileType;
{
	return fileType ? fileType : [self.fileURL pathExtension];
}

- (NSString *)localizedName;
{
	return localizedName ? localizedName : [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

- (void)openWithCompletionHandler:(void (^)(BOOL success))completionHandler;
{
	NSError *error = nil;
	BOOL ok = [self readFromURL:self.fileURL error:&error];
	if (!ok) {
		[self handleError:error userInteractionPermitted:YES];
	} else {
		documentState = UIDocumentStateNormal;
	}
	completionHandler(ok);
}

- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler;
{
	[self saveToURL:self.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
		if (success) {
			documentState = UIDocumentStateClosed;
		}
		completionHandler(success);
	}];
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError;
{
	//Do we have a bundle
	NSError *error = nil;
	NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:self.fileURL options:0 error:&error];
	id contents = nil;
	if ([wrapper isDirectory]) {
		//Bundle
		contents = wrapper;
	} else if ([wrapper isRegularFile]) {
		contents = [wrapper regularFileContents];
	}
	BOOL ok = [self loadFromContents:contents ofType:self.fileType error:&error];
	if (!ok) {
		if (outError) {
			*outError = error;
		}
	}
	[wrapper release];
	return ok;
}

- (void)saveToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^)(BOOL success))completionHandler;
{
	//Save
	NSError *error = nil;
	id contents = [self contentsForType:self.fileType error:&error];
	if ([contents isKindOfClass:[NSFileWrapper class]]) {
		BOOL ok = [(NSFileWrapper *)contents writeToURL:url options:NSFileWrapperWritingAtomic originalContentsURL:self.fileURL error:&error];
		if (!ok) {
			[self handleError:error userInteractionPermitted:YES];
		}
		if (fileURL != url) {
			[fileURL release];
			fileURL = [url retain];
		}
		completionHandler(ok);
	}	
}

#endif

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted;
{
#if USE_UIDOCUMENT
	[super handleError:error userInteractionPermitted:userInteractionPermitted];
#endif
}


@end
