//
//  WMJavascript.h
//  WMEdit
//
//  Created by Andrew Pouliot on 9/24/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//


@interface WMJavascript : NSObject

@property (nonatomic, copy) NSString *programText;

- (void)run;

@end
