//
//  WMPort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WMPort : NSObject {
    
}

- (id)stateValue;
- (BOOL)setStateValue:(id)inStateValue;

//Here we deviate slightly from the QC api, which has takeValue:fromPort:
//I'm not sure yet why that's necessary, so I'm omitting passing values and dealing with ports directly instead of values
- (BOOL)takeValueFromPort:(WMPort *)inPort;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) WMPort *originalPort;

@end
