//
//  DNDocument.h
//  WMViewer
//
//  Created by Andrew Pouliot on 8/16/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#define USE_UIDOCUMENT 0

//UIDocument is fucking broken. So, I'm subclassing object instead for now.
#if USE_UIDOCUMENT
@interface DNDocument : UIDocument
#else
@interface DNDocument : NSObject

- (id)initWithFileURL:(NSURL *)url;

@property(weak, readonly) NSURL *fileURL;
@property(readonly, copy) NSString *localizedName;  // The default implementation derives the name from the URL. Subclasses may override to provide a custom name for presentation to the user, such as in error strings.
@property(readonly, copy) NSString *fileType;       // The file's UTI. Derived from the fileURL by default.

@property(readonly) UIDocumentState documentState;

- (void)openWithCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler;

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError;
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError;

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted;

- (void)saveToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^)(BOOL success))completionHandler;
- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError;

- (void)performAsynchronousFileAccessUsingBlock:(void (^)(void))block;
#endif

@end
