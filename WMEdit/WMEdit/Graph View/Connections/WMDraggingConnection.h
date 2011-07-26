//
//  WMDraggingConnection.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMConnection.h"

@interface WMDraggingConnection : WMConnection {
    
}

@property (nonatomic) CGPoint sourcePoint;
@property (nonatomic) CGPoint destinationPoint;

@end
