//
//  WMComposition.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMPatch;

extern NSString *WMCompositionUserInfoVersionKey;
extern NSString *WMCompositionPathKey;

//This is the version of the composition file format we write
extern NSString *WMCompositionFrameworkVersion;

@interface WMCompositionSerialization : NSObject

+ (WMPatch *)patchWithPlistDictionary:(NSDictionary *)inPlistDictionary compositionBasePath:(NSString *)inBasePath userDictionary:(NSDictionary **)outUserDictionary error:(NSError **)outError;

+ (NSDictionary *)plistDictionaryWithRootPatch:(WMPatch *)inPatch userDictionary:(NSDictionary *)inUserDictionary error:(NSError **)outError;

@end
