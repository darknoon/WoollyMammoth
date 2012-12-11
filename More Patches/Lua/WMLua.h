//
//  WMLua.h
//  LAPITest
//
//  Created by Andrew Pouliot on 9/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WMGraph/WMGraph.h>

@interface WMLua : WMPatch

@property (nonatomic, copy) NSString *programText;

//The output of this iteration
@property (nonatomic, copy, readonly) NSString *consoleOutput;

@end
