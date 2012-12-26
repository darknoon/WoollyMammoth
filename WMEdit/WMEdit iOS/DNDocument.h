//
//  DNDocument.h
//  WMViewer
//
//  Created by Andrew Pouliot on 8/16/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#define USE_UIDOCUMENT 0

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
typedef NS_ENUM(NSInteger, UIDocumentChangeKind) {
    UIDocumentChangeDone,
    UIDocumentChangeUndone,
    UIDocumentChangeRedone,
    UIDocumentChangeCleared
};

typedef NS_ENUM(NSInteger, UIDocumentSaveOperation) {
    UIDocumentSaveForCreating,
    UIDocumentSaveForOverwriting
};

typedef NS_OPTIONS(NSUInteger, UIDocumentState) {
    UIDocumentStateNormal          = 0,
    UIDocumentStateClosed          = 1 << 0, // The document has either not been successfully opened, or has been since closed. Document properties may not be valid.
    UIDocumentStateInConflict      = 1 << 1, // Conflicts exist for the document's fileURL. They can be accessed through +[NSFileVersion otherVersionsOfItemAtURL:].
    UIDocumentStateSavingError     = 1 << 2, // An error has occurred that prevents the document from saving.
    UIDocumentStateEditingDisabled = 1 << 3  // Set before calling -disableEditing. The document is is busy and it is not currently safe to allow user edits. -enableEditing will be called when it becomes safe to edit again.
};

#endif

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
