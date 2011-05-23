//
//  WMStringPort.h
//  VideoLiveEffect
//
//  Created by Andrew Pouliot on 5/22/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPort.h"

@interface WMStringPort : WMPort {
}

@property (nonatomic, copy) NSString *value;


@end
