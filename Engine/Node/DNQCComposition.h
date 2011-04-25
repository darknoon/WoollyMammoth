//
//  DNQCComposition.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/11/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

enum DNQCCompositionError {
	DNQCCompositionErrorFileError = -1,
};

extern NSString *DNQCCompositionErrorDomain;

@class WMPatch;

@interface DNQCComposition : NSObject {
    NSDictionary *plistDictionary;
	NSDictionary *userDictionary;
	WMPatch *rootPatch; 
}

- (id)initWithContentsOfFile:(NSString *)inFile error:(NSError **)outError;

@property (nonatomic, readonly) NSString *frameworkVersion;

@property (nonatomic, readonly) WMPatch *rootPatch;
@property (nonatomic, readonly) NSDictionary *userDictionary;

@end
