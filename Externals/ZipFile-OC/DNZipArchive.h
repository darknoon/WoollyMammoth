//
//  DNZipArchive.h
//  PopVideo
//
//  Created by Andrew Pouliot on 9/18/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


//@class DNZipArchiveFileInfo;

NSString *const DNZipArchiveErrorDomain;

enum {
	DNZipArchiveReadError = 10,
	DNZipArchiveReadCRCInvalidError = 11,
	
	DNZipArchiveWriteError = 20,
};

@interface DNZipArchive : NSObject

//Total number of files (and directories) inside the zip file
@property (nonatomic, readonly) NSUInteger fileCount;

//The sum of the uncompressed sizes of the files; does not include filesystem overhead.
@property (nonatomic, readonly) NSUInteger uncompressedSize;

- (id)initForReadingWithFileURL:(NSURL *)inFileURL;
//You will recieve callbacks on the current queue
- (void)unzipAllToDirectoryURL:(NSURL *)inOutputDirectoryURL
					  progress:(void (^)(NSUInteger filesWritten, NSUInteger bytesWritten, NSUInteger totalBytes))progress
					completion:(void (^)(NSError *unzipError))completion;




- (id)initForWritingWithFileURL:(NSURL *)inFileURL;
- (void)appendDataFromURL:(NSURL *)inFileOrDirectoryURL asPath:(NSString *)path completion:(void (^)(NSError *zipWriteError))completion;
- (void)closeWithCompletion:(void (^)(NSError *zipWriteError))completion;





/* TODO:
 
 - (void)unzipWithFilter:(BOOL (^)(DNZipArchiveFileInfo *))inFilter toDirectoryURL:(NSURL *)inOutputDirectoryURL completion:(void (^)(NSError *unzipError))completion;
 - (void)unzipFile:(DNZipArchiveFileInfo *)inFile toDirectoryURL:(NSURL *)inOutputDirectoryURL completion:(void (^)(NSError *unzipError))completion;

 //Available for both
 - (void)enumerateZipContentsWithBlock:(void (^)(DNZipArchiveFileInfo *file, NSUInteger currentIndex, BOOL *stop))block;
 */



@end

/* TODO:
@interface DNZipArchiveFileInfo : NSObject

@property (nonatomic, readonly) NSUInteger compressedFileSize;
@property (nonatomic, readonly) NSUInteger uncompressedFileSize;
@property (nonatomic, readonly) NSDate *modificationDate;
@property (nonatomic, readonly) NSString *relativePath;

@end
*/
