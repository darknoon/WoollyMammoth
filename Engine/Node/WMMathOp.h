//
//  WMMathOp.h
//  WMViewer
//
//  Created by Andrew Pouliot on 4/28/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

typedef enum {
	WMMathOperationSum = 0,
	WMMathOperationDifference,
	WMMathOperationProduct,
	WMMathOperationQuotient,
	WMMathOperationModulus,
	WMMathOperationExponent,
	WMMathOperationMinimum,
	WMMathOperationMaximum,
	WMMathOperationInvalid,
} WMMathOperation;

@interface WMMathOp : WMPatch {
    NSArray *operations;
	WMNumberPort *inputValue;
	WMNumberPort *outputValue;
}

@end
