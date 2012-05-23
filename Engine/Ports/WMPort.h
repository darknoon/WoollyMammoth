//
//  WMPort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WMPort : NSObject

//Create a new port of the reciever class with the key property set to inKey
+ (id)portWithKey:(NSString *)inKey;

//Object value is the efficent representation of this port's input value. For instance, a GL texture or NSValue may be used
- (id)objectValue;
- (BOOL)setObjectValue:(id)inRuntimeValue;

//If the port is used as an input port and its value is disconnected, then the value of the input should be nilled out
//This should be constant for a given port class
//Examples are things like images, render objects, etc, where keeping around a value doesn't make sense for the usage and might cause performance or correctness issues
//The use of this does not guarantee that the value will be discarded, just that it can be.
- (BOOL)isInputValueTransient;

//State value is defined it terms of the value used in serialization
//State value must be a plist-compatible value, rather than an effient value used for runtime graph execution.
//By default, the state value will be the same as the object value, but if your port class is not compatible, then you must override these methods.
- (id)stateValue;
- (BOOL)setStateValue:(id)inStateValue;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;


//===== Relevant for input ports only ======
//Whether this port is compatible with being connected to the passed-in port
- (BOOL)canTakeValueFromPort:(WMPort *)inPort;

//Here we deviate slightly from the QC api, which has takeValue:fromPort:
//I'm not sure yet why that's necessary, so I'm omitting passing values and dealing with ports directly instead of values
- (BOOL)takeValueFromPort:(WMPort *)inPort;

//This is used when publishing ports. A port on the outside of a macro is created to mirror the port on the inside.
//This points to the original port
@property (nonatomic, weak) WMPort *originalPort;

//The port to which this port is connected
//TODO: make this private state only shared with the engine
@property (nonatomic, weak) WMPort *connectedPort;

@end
