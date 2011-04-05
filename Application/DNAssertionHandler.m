//
//  DNAssertionHandler.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/7/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "DNAssertionHandler.h"

@implementation DNAssertionHandler

- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...;
{
    va_list args;
    va_start(args, format);
	NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
	NSLog(@"%@", formattedString);
	va_end(args);
	[super handleFailureInMethod:selector object:object file:fileName lineNumber:line description:format, args];
}

- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...;
{
    va_list args;
    va_start(args, format);
	NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
	NSLog(@"%@", formattedString);
	va_end(args);
	[super handleFailureInFunction:functionName file:fileName lineNumber:line description:format, args];
	
}


@end
