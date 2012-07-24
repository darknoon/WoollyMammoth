//
//  DNZipArchive.m
//  PopVideo
//
//  Created by Andrew Pouliot on 9/18/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "DNZipArchive.h"

#import "unzip.h"

#import "zip.h"

NSString *const DNZipArchiveErrorDomain = @"com.darknoon.DNZipArchive";

//TODO: actually localize failure strings

const NSUInteger DNZipArchiveReadBufferSize = 4096; 

@interface DNZipArchive ()
- (void)_enumerateZipContentsWithPrivateBlock:(void (^)(unz_file_info *info, NSString *filePath, BOOL isDirectory, NSError *error, BOOL *stop))block;
@end

@implementation DNZipArchive {
	unzFile unzipFile;
	
	zipFile _zipFile;
	
	dispatch_queue_t _work_queue;
}
@synthesize fileCount = _fileCount;
@synthesize uncompressedSize = _uncompressedSize;

- (id)initForReadingWithFileURL:(NSURL *)inFileURL;
{
	self = [super init];
	unzipFile = unzOpen( [[inFileURL path] cStringUsingEncoding:NSUTF8StringEncoding] );
	if (unzipFile) {
		unz_global_info fileInfo = {};
		if (unzGetGlobalInfo(unzipFile, &fileInfo) == UNZ_OK) {
			_fileCount = fileInfo.number_entry;
			
			NSLog(@"%lu entries in the zip file", fileInfo.number_entry);
			
			__block NSUInteger totalBytes = 0;
			[self _enumerateZipContentsWithPrivateBlock:^(unz_file_info *info, NSString *filePath, BOOL isDirectory, NSError *error, BOOL *stop) {
				NSLog(@"filepath: %@ unzipped bytes: %ld", filePath, info->uncompressed_size);
				//Find out how many bytes the write will be
				if (!error) {
					totalBytes += info->uncompressed_size;
				}
			}];
			_uncompressedSize = totalBytes;

		}
		return self;
	} else {
		return nil;
	}
}

- (id)initForWritingWithFileURL:(NSURL *)inFileURL;
{
	self = [super init];
	
	_zipFile = zipOpen( [[inFileURL path] cStringUsingEncoding:NSUTF8StringEncoding], APPEND_STATUS_CREATE);
	if (_zipFile) {
		
		_fileCount = 0;
		_uncompressedSize = 0;
		
		return self;
	} else {
		return nil;
	}
}

- (void)dealloc
{
	if (_work_queue) {
		dispatch_release(_work_queue);
		_work_queue = NULL;
	}
	
	if (unzipFile) {
		unzClose(unzipFile);
		unzipFile = NULL;
	}
}


- (BOOL)_appendData:(NSData *)data asFile:(NSString *)path error:(NSError **)error;
{
	//This is perhaps dumb.
	//TODO: Check what this is doing:
	time_t current;
	time( &current );
	zip_fileinfo zipInfo = {0};
	zipInfo.dosDate = (unsigned long) current;
	//End perhaps dumb

	int ret = zipOpenNewFileInZip(_zipFile,
								  (const char*) [path cStringUsingEncoding:NSUTF8StringEncoding],
								  &zipInfo,
								  NULL,0,
								  NULL,0,
								  NULL,//comment
								  Z_DEFLATED,
								  Z_DEFAULT_COMPRESSION);
	
	if (ret != ZIP_OK) {
		NSError *zipWriteError = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveWriteError userInfo:nil];
		if (error) *error = zipWriteError;
		return NO;
	}
		
	unsigned int dataLen = [data length];
	ret = zipWriteInFileInZip( _zipFile, (const void*)[data bytes], dataLen);
	
	if (ret != ZIP_OK) {
		NSError *zipWriteError = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveWriteError userInfo:nil];
		if (error) *error = zipWriteError;
		return NO;
	}
	
	ret = zipCloseFileInZip( _zipFile );
	
	if (ret != ZIP_OK) {
		NSLog(@"Error closing file in zip. Continuing.");
	}
	
	return YES;
}

- (void)appendDataFromURL:(NSURL *)inFileOrDirectoryURL asPath:(NSString *)path completion:(void (^)(NSError *zipWriteError))completion;
{
	
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	//TODO: create in a more sane place!
	if (!_work_queue) {
		_work_queue = dispatch_queue_create("com.darknoon.DNZipArchive.work_queue", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(_work_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
	}
	
	dispatch_async(_work_queue, ^{
		//Capture self so we can not reach dealloc before this finishes
		[self self];
		
		//Is it a directory?
		NSFileManager *fm = [NSFileManager defaultManager];
		
		//TODO: support recursion properly
		
		NSEnumerator *rec = [fm enumeratorAtPath:inFileOrDirectoryURL.path];
		
		if (!rec) {
			rec = [[NSArray arrayWithObject:inFileOrDirectoryURL.path] objectEnumerator];
		}
		
		for (NSString *subpath in rec) {
			
			NSURL *sourceURL = [[NSURL URLWithString:subpath relativeToURL:inFileOrDirectoryURL] absoluteURL];
			
			//Take the inFileOrDirectoryURL and remove the... hmm
			//TODO: This is obviously not correct :(
			NSString *relativePath = [path stringByAppendingPathComponent:subpath];
			
			NSLog(@"Adding url %@ as path %@", sourceURL, relativePath);
			
			//TODO: stream data into file with dispatch_io :D
			
			NSError *readDataError = nil;
			NSData *data = [NSData dataWithContentsOfURL:sourceURL options:NSDataReadingMapped error:&readDataError];
			if (!data) {
				dispatch_async(callingQueue, ^{
					NSLog(@"Couldn't read file data: %@", sourceURL);
					NSError *zipWriteError = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveWriteError userInfo:nil];
					completion(zipWriteError);
				});
				return;
			}
			
			//Read data, now append it
			NSError *appendError = nil;
			BOOL ok = [self _appendData:data asFile:relativePath error:&appendError];
			
			if (!ok) {
				dispatch_async(callingQueue, ^{
					completion(appendError);
				});
				return;
			}
			
		}
		
		//Added all files recursively, yay!
		dispatch_async(callingQueue, ^{
			completion(nil);
		});

	});	
}

- (void)closeWithCompletion:(void (^)(NSError *zipWriteError))completion;
{
	dispatch_async(_work_queue, ^{
		//Capture self so we can not reach dealloc before this finishes
		[self self];

		if (_zipFile) {
			int ret = zipClose(_zipFile, NULL);
			_zipFile = NULL;
			if (ret != ZIP_OK) {
				NSError *zipWriteError = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveWriteError userInfo:nil];
				completion(zipWriteError);
			} else {
				completion(NULL);
			}
		}
		
	});
}

- (BOOL)_zipFilenameIsDirectory:(NSString *)inFileName;
{
	if (inFileName.length == 0) return NO;
	unichar lastChar = [inFileName characterAtIndex:inFileName.length - 1];
	return lastChar == '/' || lastChar == '\\';
}

- (void)_enumerateZipContentsWithPrivateBlock:(void (^)(unz_file_info *info, NSString *filePath, BOOL isDirectory, NSError *error, BOOL *stop))block;
{
	if (_fileCount == 0) return;
	
	BOOL stop = NO;
	int status = unzGoToFirstFile(unzipFile);
	if (status != UNZ_OK) {
		NSString *description = @"Couldn't seek to first file in zip";
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil];
		NSError *error = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveReadError userInfo:userInfo];
		block(NULL, nil, NO, error, &stop);
		return;
	}
	
	do {
		@autoreleasepool {
			//Get the info about the file, including the length of the filename
			unz_file_info fileInfo ={0};
			status = unzGetCurrentFileInfo(unzipFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
			if (status != UNZ_OK) { //Couldn't get the file info
				NSString *description = @"Error getting file info in zip.";
				NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil];
				NSError *error = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveReadError userInfo:userInfo];
				block(NULL, nil, NO, error, &stop);
				break;
			}
			
			//Create a buffer to hold the filename and copy into the buffer
			const size_t filenameBufferLength = fileInfo.size_filename;
			char *filename = (char*)malloc(filenameBufferLength);
			status = unzGetCurrentFileInfo(unzipFile, NULL, filename, filenameBufferLength, NULL, 0, NULL, 0);
			if (status != UNZ_OK) { //Couldn't get the file info
				NSString *description = @"Error getting file name in zip.";
				NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil];
				NSError *error = [[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveReadError userInfo:userInfo];
				block(NULL, nil, NO, error, &stop);
				break;
			}
			
			// check if it contains a directory
			NSString *strPath = [[NSString alloc] initWithBytesNoCopy:filename length:filenameBufferLength encoding:NSUTF8StringEncoding freeWhenDone:YES];
			BOOL isDirectory = [self _zipFilenameIsDirectory:strPath];
			
			//Replace Windows-style file path separators with unix-style file paths
			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
			
			//Call our iteration block
			block(&fileInfo, strPath, isDirectory, nil, &stop);
			
			status = unzGoToNextFile(unzipFile);
		}
	} while(!stop && status == UNZ_OK);
	
}

- (void)unzipAllToDirectoryURL:(NSURL *)inOutputDirectoryURL progress:(void (^)(NSUInteger filesWritten, NSUInteger bytesWritten, NSUInteger totalBytes))progress completion:(void (^)(NSError *unzipError))completion;
{
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	if (!_work_queue) {
		_work_queue = dispatch_queue_create("com.darknoon.DNZipArchive.work_queue", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(_work_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
	}
	
	dispatch_async(_work_queue, ^{

		__block NSUInteger bytesWritten = 0;
		__block NSUInteger filesWritten = 0;
		__block BOOL ok = YES;
		NSFileManager *manager = [NSFileManager defaultManager];
		
		NSString *basePath = [inOutputDirectoryURL path];
		//Capture self so we can not reach dealloc before this finishes
		[self _enumerateZipContentsWithPrivateBlock:^(unz_file_info *info, NSString *filePath, BOOL isDirectory, NSError *error, BOOL *stop) {
			if (error) {
				ok = NO;
				dispatch_async(callingQueue, ^{
					if (completion) {
						completion(error);
					}
				});
			} else {
				NSError *error;
				if (isDirectory) {
					//Attempt to make the directory
					error = nil;
					NSLog(@"attempting to create directory: %@", [basePath stringByAppendingPathComponent:filePath]);
					ok = [manager createDirectoryAtPath:[basePath stringByAppendingPathComponent:filePath] withIntermediateDirectories:YES attributes:nil error:&error];
					if (!ok) {
						dispatch_async(callingQueue, ^{
							NSDictionary *userInfo = error ? [[NSDictionary alloc] initWithObjectsAndKeys:error, NSUnderlyingErrorKey, nil] : nil;
							completion([[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveWriteError userInfo:userInfo]);
						});
						*stop = YES;
						return;
					}
				} else {
					//Attempt to make any directories this file is in
					error = nil;
					NSLog(@"attempting to create directory: %@", [[basePath stringByAppendingPathComponent:filePath] stringByDeletingLastPathComponent]);
					ok = [manager createDirectoryAtPath:[[basePath stringByAppendingPathComponent:filePath] stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
					if (!ok) {
						dispatch_async(callingQueue, ^{
							NSDictionary *userInfo = error ? [[NSDictionary alloc] initWithObjectsAndKeys:error, NSUnderlyingErrorKey, nil] : nil;
							completion([[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveWriteError userInfo:userInfo]);
						});
						*stop = YES;
						return;
					}
					
					NSLog(@"attempting to unzip file to: %@", [basePath stringByAppendingPathComponent:filePath]);
					int status = unzOpenCurrentFile(unzipFile);
					if (status == UNZ_OK) {
						//Attempt to read out the file and write to target file
						FILE *fp = fopen([[basePath stringByAppendingPathComponent:filePath] UTF8String], "wb");
						if (fp) {
							int readBytesOrStatus = 0;
							do {
								//Create a big fixed-size buffer on the stack. I hope this is ok...
								unsigned char buffer[DNZipArchiveReadBufferSize];
								
								readBytesOrStatus = unzReadCurrentFile(unzipFile, buffer, DNZipArchiveReadBufferSize);
								if (readBytesOrStatus > 0) {
									fwrite( (const void *)buffer, readBytesOrStatus, 1, fp);
									bytesWritten += (NSUInteger)readBytesOrStatus;
								} else if(readBytesOrStatus < 0) { //Zip file read error
									//TODO: better error reporting here
									ok = NO;
									dispatch_async(callingQueue, ^{
										completion([[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveReadError userInfo:nil]);
									});
									*stop = YES;
									break;
								}
							} while (readBytesOrStatus > 0);
							//Done
							//TODO: handle fclose error?
							fclose(fp);
							if (ok) {
								filesWritten++;
							}
							int status = unzCloseCurrentFile(unzipFile);
							if (status == UNZ_CRCERROR) {
								NSLog(@"crc error on file %@", filePath);
//								//We read the file ok, but the CRC was invalid
//								ok = NO;
//								dispatch_async(callingQueue, ^{
//									completion([[NSError alloc] initWithDomain:DNZipArchiveErrorDomain code:DNZipArchiveReadCRCInvalidError userInfo:nil]);
//								});
//								*stop = YES;
//								return;
							}
							
							//Update progress
							if (progress) {
								dispatch_async(callingQueue, ^{
									progress(filesWritten, bytesWritten, _uncompressedSize);
								});
							}
						} else { //fopen failure
							//TODO: report unable to open file error
							ok = NO;
							NSLog(@"DNZipArchive ERROR: unable to open file for writing %@", [basePath stringByAppendingPathComponent:filePath]);
						}
					} else {//Open zip current file error
						//TODO: report better error!
						ok = NO;
						NSLog(@"DNZipArchive ERROR: unable to open zip file part for reading %@", [basePath stringByAppendingPathComponent:filePath]);
					}
				}
			}
		}];
		//Yay, we completed successfully
		if (ok) {
			dispatch_async(callingQueue, ^{
				completion(nil);
			});
		}
	});
}

@end
