//
//  WMPatchCategories.h
//  WMEdit
//
//  Created by Michael Deitcher on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *WMPatchCategoryDevice;
extern NSString *WMPatchCategoryNetwork;
extern NSString *WMPatchCategoryGeometry;
extern NSString *WMPatchCategoryImage;
extern NSString *WMPatchCategoryUtil;
extern NSString *WMPatchCategoryUnknown;

@interface WMPatchCategories : NSObject

+ (WMPatchCategories *)sharedInstance;

@property (nonatomic, strong) NSMutableDictionary *categoriesMap;

- (void)addClassWithName:(Class)inClass key:(NSString*)className;
- (NSArray*)patchCategoriesArray;
- (NSArray*)patchNamesArrayFromCategory:(NSString*)category;
- (NSDictionary*)patchesForCategory:(NSString*)categoryName;
- (NSString*)classFromCategoryAndName:(NSString*)category name:(NSString*)name;

@end
