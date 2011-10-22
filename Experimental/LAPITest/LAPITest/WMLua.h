//
//  WMLua.h
//  LAPITest
//
//  Created by Andrew Pouliot on 9/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMLua : NSObject

@property (nonatomic, copy) NSString *programText;

- (void)run; 

@end
