//
//  WMPatchCategories.m
//  WMEdit
//
//  Created by Michael Deitcher on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchCategories.h"

#import "WMPatch.h"

NSString *WMPatchCategoryNetwork = @"Network";
NSString *WMPatchCategoryRender = @"Render";
NSString *WMPatchCategoryInput = @"Input";
NSString *WMPatchCategoryUnknown = @"Unknown";

NSArray *WMPatchCategoryNames;

@implementation WMPatchCategories
@synthesize categoriesMap = _categoriesMap;

+ (WMPatchCategories *)sharedInstance;
{
    static WMPatchCategories *sharedInstance=nil;
    if (!sharedInstance) {
        sharedInstance = [[WMPatchCategories alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    self.categoriesMap = [NSMutableDictionary dictionary];    
    return self;
}

- (void)dealloc {
    [_categoriesMap release];
    [super dealloc];
}

- (NSDictionary *)categoriesMap;
{
    return [[_categoriesMap copy] autorelease];
}
- (void)addClassWithName:(Class)inClass key:(NSString*)className;
{
    NSString *category = [inClass category];
    NSMutableArray *classesArray = (NSMutableArray*)[_categoriesMap objectForKey:category];
    if( classesArray == nil ){
        classesArray = [NSMutableArray array];
        [_categoriesMap setObject:classesArray forKey:category];
    }
    [classesArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:className, @"className", NSStringFromClass(inClass), @"class", nil]];
}

- (NSArray *)patchCategoriesArray;
{
    NSArray* array =  [[self categoriesMap] allKeys];	
    return array;
}

- (NSArray*)patchNamesArrayFromCategory:(NSString*)category;
{
    NSArray* details = [_categoriesMap objectForKey:category];    
    NSMutableArray* toReturn = [[NSMutableArray alloc] initWithCapacity:[details count]];
    for (NSDictionary* detail in details) {
        [toReturn addObject:[detail objectForKey:@"className"]];
    }
    return [toReturn autorelease];
}

- (NSDictionary *)patchesForCategory:(NSString *)categoryName;
{
    NSLog(@"pateCategories");
    return [[self categoriesMap] objectForKey:categoryName];	
}

- (NSString*)classFromCategoryAndName:(NSString*)category name:(NSString*)name;
{
    NSDictionary* patches = [self patchesForCategory:category];
    for (NSDictionary* detail in patches) {
        if( [(NSString*)[detail objectForKey:@"className"] compare:name] == NSOrderedSame){
            return [[(NSString*)[detail objectForKey:@"class"] copy] autorelease];
        }
    }    
    return @"unknown";
}
@end
