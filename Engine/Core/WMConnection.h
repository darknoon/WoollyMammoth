//
//  WMConnection.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/12/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WMConnection : NSObject {
    
}

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *sourceNode;
@property (nonatomic, copy) NSString *sourcePort;

@property (nonatomic, copy) NSString *destinationNode;
@property (nonatomic, copy) NSString *destinationPort;


@end
