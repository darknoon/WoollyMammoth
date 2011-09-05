//
//  WMSplitter.m
//  WMViewer
//
//  Created by Andrew Pouliot on 4/28/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMSplitter.h"

#import "WMNumberPort.h"
#import "WMBooleanPort.h"
#import "WMIndexPort.h"
#import "WMColorPort.h"

@implementation WMSplitter

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (BOOL)setPlistState:(id)inPlist;
{
	//TODO: store a mapping of port types too?
	NSString *portClassName = [inPlist objectForKey:@"portClass"];
	WMPort *inputPort = nil;
	WMPort *outputPort = nil;
	if ([portClassName isEqualToString:@"QCNumberPort"]) {
		inputPort = [[WMNumberPort alloc] init];
		outputPort = [[WMNumberPort alloc] init];
	} else if ([portClassName isEqualToString:@"QCBooleanPort"]) {
		inputPort = [[WMBooleanPort alloc] init];
		outputPort = [[WMBooleanPort alloc] init];
	} else if ([portClassName isEqualToString:@"QCIndexPort"]) {
		inputPort = [[WMIndexPort alloc] init];
		outputPort = [[WMIndexPort alloc] init];
	} else if ([portClassName isEqualToString:@"QCColorPort"]) {
		inputPort = [[WMColorPort alloc] init];
		outputPort = [[WMColorPort alloc] init];
	} else {
		NSLog(@"Attempt to create unsupported splitter of type: %@", portClassName);
		return NO;
	}
	inputPort.key = @"input";
	outputPort.key = @"output";
	[self addInputPort:inputPort];
	[self addOutputPort:outputPort];

	return [super setPlistState:inPlist];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	WMPort *input = [self inputPortWithKey:@"input"];
	WMPort *output = [self outputPortWithKey:@"output"];
	return [output takeValueFromPort:input];
}

@end
