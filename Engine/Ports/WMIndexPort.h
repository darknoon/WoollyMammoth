//
//  WMIndexPort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPort.h"

enum QCBlendMode {
	QCBlendModeReplace = 0, //ie, no blending
	QCBlendModeOver,
	QCBlendModeAdd,
};

@interface WMIndexPort : WMPort {
}

@property (nonatomic) NSUInteger index;

@end
