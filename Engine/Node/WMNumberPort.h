//
//  WMNumberPort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPort.h"

//TODO: offer a port with double or float values for performance?
@interface WMNumberPort : WMPort {
}
@property (nonatomic) double value;


@end
