//
//  WMCompositionLibrary.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCompositionLibrary.h"
#import "WMPatch.h"
#import "NSString+URLEncoding.h"
#import "WMBundleDocument.h"

NSString *CompositionsChangedNotification = @"CompositionsChangedNotification";

@interface WMCompositionLibrary(myPascalLikeStuff)
- (void)findAllDocuments;
@end

@implementation WMCompositionLibrary {
	NSMutableArray *compositions;
}

- (id)init {
    self = [super init];
    if (self) {
        compositions = [[NSMutableArray alloc] init];
        [self findAllDocuments];
    }
    return self;
}

+ (WMCompositionLibrary *)compositionLibrary {
    static WMCompositionLibrary *_singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _singleton = [[WMCompositionLibrary alloc] init];
    });
    return _singleton;
}

#pragma mark our default stuff

// this will go up the path until it finds an existing directory
// and will add each subpath and return YES if succeeds, NO if fails:
//
// Temporary Directory stuff: useful code.

BOOL directoryOK(NSString *path) {
	BOOL isDirectory;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
		// NSDictionary *dict = [NSDictionary dictionaryWithObject:
		//[NSNumber numberWithUnsignedLong:0777] forKey:NSFilePosixPermissions];
		if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:NULL]) 
			return NO;
	}
	return YES;
}

NSString * existingPath(NSString *path) {
	while (path && ![path isEqualToString:@""]
		   && ![[NSFileManager defaultManager] fileExistsAtPath:path])
		path = [path stringByDeletingLastPathComponent];
	return path;	
}

NSArray *directoriesToAdd(NSString *path, NSString *existing) {
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:4];
	if (path != nil && existing != nil) {
		while (![path isEqualToString:existing]) {
			[a insertObject:[path lastPathComponent] atIndex:0];
			path = [path stringByDeletingLastPathComponent];
		}
	}
	return a;
}

- (BOOL)createWritableDirectory:(NSString *)path {
	BOOL isDirectory;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]
		&& isDirectory && [fileManager isWritableFileAtPath:path])
		return YES; // no work to do
	else {
		NSString *existing = existingPath(path);
		NSArray *dirsToAdd = directoriesToAdd(path,existing);
		int i;
		BOOL good = YES;
		for (i = 0; i < [dirsToAdd count]; i++) {
			existing = [existing stringByAppendingPathComponent:[dirsToAdd objectAtIndex:i]];
			if (!directoryOK(existing)) {
				good = NO;
				break;
			}
		}
		return good;
	}
}

- (NSString *)documentsDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

- (NSString *)pathForResource:(NSString *)shortName
{
	return [[[self documentsDirectory] stringByAppendingPathComponent:shortName] stringByAppendingPathExtension:WMBundleDocumentExtension];
}

- (NSURL *)URLForResourceShortName:(NSString *)shortName {
    return [NSURL fileURLWithPath:[self pathForResource:shortName]];
}

- (NSString *)shortNameFromURL:(NSURL *)url;
{
    return [[[[url absoluteString] URLDecodedString]lastPathComponent] stringByDeletingPathExtension];
}

- (NSArray *)compositions;
{
	return [[compositions copy] autorelease];
}

- (BOOL)savePropertyList:(id)d toURL:(NSURL *)inURL {
	NSString *errorString = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:d format:kCFPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	
	return [data writeToURL:inURL atomically:YES];
}

- (NSMutableDictionary *)propertyListWithData:(NSData *)data {
	if (!data) return nil;
	
    NSString * errorString = nil;
	NSPropertyListFormat format;	
	NSMutableDictionary *dict = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorString];
	return dict;
}


- (WMPatch *)compositionWithURL:(NSURL *)inURL;
{
    NSData *d = [NSData dataWithContentsOfURL:inURL];
    if (d) {
        id propertyList = [self propertyListWithData:d];
        if (propertyList) {
			WMPatch *patch = [[[WMPatch alloc] initWithPlistRepresentation:propertyList] autorelease];
			return patch;
		}
    }
	return nil;
}

- (void)findAllDocuments {
    NSString *saveFolder = [self documentsDirectory];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:saveFolder error:&error];
    for (NSString *file in files) {
        NSString *path = [saveFolder stringByAppendingPathComponent:file];
        if ([[path pathExtension] isEqualToString:WMBundleDocumentExtension]) { 
            [compositions addObject:[NSURL fileURLWithPath:path]];
		} else if ([[path pathExtension] isEqualToString:@"wmpatch"]) {
			[compositions addObject:[NSURL fileURLWithPath:path]];
		}
    }
}

NSString *base62FromBase10(int num)
{
	char chars[62] = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	int r;
	NSString *newNumber = @"";
	
	// in r we have the offset of the char that was converted to the new base
	while(num >= 62)
	{
		r = num % 62;
		newNumber = [NSString stringWithFormat:@"%C%@", chars[r],newNumber];
		num = num / 62;
	}
	// the last number to convert
	newNumber = [NSString stringWithFormat:@"%C%@", chars[num],newNumber];
	
	return newNumber;
}

- (NSString *)timeAsCompactString {
	int num = (int)(rint(CFAbsoluteTimeGetCurrent()));
	return base62FromBase10(num);
}

- (NSString *)pathForThumbOfComposition:(NSURL *)inFileURL {
    return [[inFileURL path] stringByAppendingPathComponent:@"preview.png"];
}

- (UIImage *)imageForCompositionPath:(NSURL *)fullComposition {
    NSString *path = [self pathForThumbOfComposition:fullComposition];
    NSData *d = [NSData dataWithContentsOfFile:path];
    if (d) return [UIImage imageWithData:d];
    return [UIImage imageNamed:@"missing_effect_thumb.jpg"];
}

- (BOOL)renameComposition:(NSURL *)oldFileURL to:(NSString *)newName {
    NSString *oldThumbPath = [self pathForThumbOfComposition:oldFileURL];
    NSURL *newURL = [self URLForResourceShortName:newName];
    NSString *newThumbPath = [self pathForThumbOfComposition:newURL];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] moveItemAtURL:oldFileURL toURL:newURL error:&error] &&
        [[NSFileManager defaultManager] moveItemAtPath:oldThumbPath toPath:newThumbPath error:&error]) {
        [compositions replaceObjectAtIndex:[compositions indexOfObject:oldFileURL] withObject:newURL];
        [[NSNotificationCenter defaultCenter] postNotificationName:CompositionsChangedNotification object:oldFileURL];
        return  YES;
    }
    return  NO;
}

- (void)dealloc
{
    [super dealloc];
}


@end
