//
//  WMCompositionLibrary.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCompositionLibrary.h"

#import "NSString+URLEncoding.h"
#import <WMGraph/WMGraph.h>
#import <WMGraph/DNKVC.h>


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
    return [[[[url absoluteString] URLDecodedString] lastPathComponent] stringByDeletingPathExtension];
}

- (NSArray *)compositions;
{
	return [compositions copy];
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

- (UIImage *)imageForCompositionPath:(NSURL *)fullComposition;
{
    NSString *path = [self pathForThumbOfComposition:fullComposition];
    NSData *d = [NSData dataWithContentsOfFile:path];
    if (d) return [UIImage imageWithData:d];
    return [UIImage imageNamed:@"missing_effect_thumb.jpg"];
}


#pragma mark -

- (NSUInteger)countOfCompositions;
{
	return compositions.count;
}

- (void)insertCompositions:(NSArray *)array atIndexes:(NSIndexSet *)indexes;
{
	[compositions insertObjects:array atIndexes:indexes];
}

- (void)insertObject:(NSURL *)inObject inCompositionsAtIndex:(NSUInteger)idx
{
	[compositions insertObject:inObject atIndex:idx];
}

- (void)removeCompositionsObject:(NSURL *)object;
{
	[compositions removeObject:object];
}

- (void)addCompositionURL:(NSURL *)inFileURL;
{
	[[self mutableArrayValueForKey:KVC(self, compositions)] addObject:inFileURL];
}

- (void)removeCompositionURL:(NSURL *)inFileURL;
{
	[[self mutableArrayValueForKey:KVC(self, compositions)] removeObject:inFileURL];
}


@end
