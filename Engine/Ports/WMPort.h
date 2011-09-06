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

+ (id)portWithKey:(NSString *)inKey;

//Object value is the efficent representation of this port's input value. For instance, a GL texture or NSValue may be used
- (id)objectValue;
- (BOOL)setObjectValue:(id)inRuntimeValue;

//State value is defined it terms of the value used in serialization
//State value must be a plist-compatible value, rather than an effient value used for runtime graph execution.
//By default, the state value will be the same as the object value, but if your port class is not compatible, then you must override these methods.
- (id)stateValue;
- (BOOL)setStateValue:(id)inStateValue;

//Whether this port is compatible with being connected to the passed-in port
- (BOOL)canTakeValueFromPort:(WMPort *)inPort;

//Here we deviate slightly from the QC api, which has takeValue:fromPort:
//I'm not sure yet why that's necessary, so I'm omitting passing values and dealing with ports directly instead of values
- (BOOL)takeValueFromPort:(WMPort *)inPort;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) WMPort *originalPort;

@end
