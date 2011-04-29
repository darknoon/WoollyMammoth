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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCSplitter"]];
	[pool drain];
}

- (BOOL)setPlistState:(id)inPlist;
{
	//TODO: store a mapping of port types too?
	NSString *portClassName = [inPlist objectForKey:@"portClass"];
	WMPort *inputPort = nil;
	WMPort *outputPort = nil;
	if ([portClassName isEqualToString:@"QCNumberPort"]) {
		inputPort = [[[WMNumberPort alloc] init] autorelease];
		outputPort = [[[WMNumberPort alloc] init] autorelease];
	} else if ([portClassName isEqualToString:@"QCBooleanPort"]) {
		inputPort = [[[WMBooleanPort alloc] init] autorelease];
		outputPort = [[[WMBooleanPort alloc] init] autorelease];
	} else if ([portClassName isEqualToString:@"QCIndexPort"]) {
		inputPort = [[[WMIndexPort alloc] init] autorelease];
		outputPort = [[[WMIndexPort alloc] init] autorelease];
	} else if ([portClassName isEqualToString:@"QCColorPort"]) {
		inputPort = [[[WMColorPort alloc] init] autorelease];
		outputPort = [[[WMColorPort alloc] init] autorelease];
	} else {
		NSLog(@"Attempt to create unsupported splitter of type: %@", portClassName);
		[self release];
		return nil;
	}
	inputPort.name = @"input";
	outputPort.name = @"output";
	[self addInputPort:inputPort];
	[self addOutputPort:outputPort];

	return [super setPlistState:inPlist];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	WMPort *input = [self inputPortWithName:@"input"];
	WMPort *output = [self outputPortWithName:@"output"];
	return [output takeValueFromPort:input];
}

@end
