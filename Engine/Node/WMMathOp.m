//
//  WMMathOp.m
//  WMViewer
//
//  Created by Andrew Pouliot on 4/28/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMMathOp.h"


@implementation WMMathOp

+ (NSString *)category;
{
    return WMPatchCategoryRender;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCMath"]];
	[pool drain];
}


- (BOOL)setPlistState:(id)inPlist;
{
	int numberOfOperations = [[inPlist objectForKey:@"numberOfOperations"] intValue];
	for (int i=0; i<numberOfOperations; i++) {
		WMNumberPort *operandPort = [[[WMNumberPort alloc] init] autorelease];
		operandPort.key = [NSString stringWithFormat:@"operand_%d", i + 1];
		[self addInputPort:operandPort];
	}
	
	NSDictionary *customInputPortStates = [inPlist objectForKey:@"customInputPortStates"];
	NSMutableArray *mutableOperations = [NSMutableArray array];
	for (int i=0; i<numberOfOperations; i++) {
		NSString *operationName = [NSString stringWithFormat:@"operation_%d", i + 1];
		//TODO: SECURITY: safety here
		NSNumber *operationNumber = [[customInputPortStates objectForKey:operationName] objectForKey:@"value"];
		WMMathOperation op = [operationNumber intValue];
		if (op < WMMathOperationInvalid) {
			[mutableOperations addObject:operationNumber];
		}
	}
	operations = [mutableOperations copy];

	return [super setPlistState:inPlist];
}

- (WMNumberPort *)operandPortAtIndex:(int)i;
{
	return (WMNumberPort *)[self inputPortWithKey:[NSString stringWithFormat:@"operand_%d", i + 1]];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (operations.count == 0) {
		return NO;
	}
	//In general, be fault tolerant here
	
	float value = inputValue.value;
	if (!isfinite(value))
		value = 0.0f;
	for (int i=0; i<operations.count; i++) {
		WMMathOperation operation = [[operations objectAtIndex:i] intValue];
		float operand = [self operandPortAtIndex:i].value;
		switch (operation) {
			case WMMathOperationSum:
				value += operand;
				break;
			case WMMathOperationDifference:
				value -= operand;
				break;
			case WMMathOperationProduct:
				value *= operand;
				break;
			case WMMathOperationQuotient:
				if (isfinite(operand) && operand != 0.0f) {
					value /= operand;
				} else {
					value = 0.0f;
				}
				break;
			case WMMathOperationModulus:
				if (isfinite(operand) && operand != 0.0f) {
					value = fmodf(value, operand);
				}
			case WMMathOperationExponent:
				value = powf(value, operand);
				break;
			case WMMathOperationMinimum:
				value = MIN(value, operand);
				break;
			case WMMathOperationMaximum:
				value = MAX(value, operand);
				break;			
			default:
				return NO;
		}
	}
	outputValue.value = value;
	return YES;
}

- (NSString *)descriptionForOperation:(WMMathOperation)operation;
{
	switch (operation) {
		case WMMathOperationSum:
			return @"+";
		case WMMathOperationDifference:
			return @"-";
		case WMMathOperationProduct:
			return @"\u2715";
		case WMMathOperationQuotient:
			return @"\u00F7";
		case WMMathOperationExponent:
			return @"Pow";
		case WMMathOperationMinimum:
			return @"Min";
		case WMMathOperationMaximum:
			return @"Max";
		default:
			return @"?";
	}
}

- (NSString *)description;
{
	NSMutableString *operationString = [NSMutableString string];
	for (int i=0; i<operations.count; i++) {
		WMMathOperation operation = [[operations objectAtIndex:i] intValue];
		[operationString appendFormat: (i == operations.count - 1 ? @"%@, " : @"%@"), [self descriptionForOperation: operation]];
	}
	return [NSString stringWithFormat:@"<%@ : %p>{%@}", NSStringFromClass([self class]), self, operationString];
}

@end
