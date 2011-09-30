//
//  WMJavascript.m
//  WMEdit
//
//  Created by Andrew Pouliot on 9/24/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMJavascript.h"

#import "DNTimingMacros.h"
#import "NSData_Base64Extensions.h"

NSString *const WMJavascript_DEBUG_NAME =  @"blahNameHere";

NSString *const WMJSIOTypeStructuredBuffer = @"wmsbuf";

@interface WMWebViewDelegate : NSObject <UIWebViewDelegate>

@property (nonatomic, strong) void (^urlCallbackBlock)(NSURL *inURL);

@end

@implementation WMWebViewDelegate
@synthesize urlCallbackBlock;
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	if (urlCallbackBlock) {
		urlCallbackBlock(request.URL);
	}
	return NO;
}
@end

@implementation WMJavascript {
	WMWebViewDelegate *delegateReflector;
}
@synthesize programText;

+ (UIWebView *)sharedWebView;
{
	static UIWebView *sharedWebView;
	if (!sharedWebView) {
		sharedWebView = [[UIWebView alloc] initWithFrame:CGRectZero];

		NSError *error = nil;
		for (NSString *includeFile in [NSArray arrayWithObjects:@"WMAPI", @"WMAPIBuffer", nil]) {
			NSString *apiFile = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:includeFile withExtension:@"js"] encoding:NSUTF8StringEncoding error:&error];
			[[[self class] sharedWebView] stringByEvaluatingJavaScriptFromString:apiFile];
		}
	}
	return sharedWebView;
}

- (id)init;
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

+ (void)setProgramText:(NSString *)inProgramText forName:(NSString *)inName;
{
	NSString *jsString = [NSString stringWithFormat:@"WM_loadScriptNamed('%@', (function(){%@; return main})() )", inName, inProgramText];
	[[self sharedWebView] stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)setProgramText:(NSString *)inProgramText;
{
	programText = inProgramText;
	[[self class] setProgramText:programText forName:WMJavascript_DEBUG_NAME];
}

- (void)encodeObjectForWMJSAPI:(id)inObject;
{
	/*
	 NSString => "string"
	 image    => X
	 WMStructuredBuffer => Buffer({<structure defn>}, "<data byte string>")
	 */
}

- (id)decodeObjectFromWMJSAPI:(id)obj;
{
	if ([obj isKindOfClass:[NSDictionary class]]) {
		NSDictionary *specialDictionary = obj;
		id type = [specialDictionary objectForKey:@"_wmtype"];
		if ([type isEqual:WMJSIOTypeStructuredBuffer]) {
			//look for the byte string, convert to data
			NSString *dataAsString = [specialDictionary objectForKey:@"data"];
			return [NSData dataWithBase64EncodedString:dataAsString];
		}
	}
	return nil;
}

- (void)run;
{
	delegateReflector = [[WMWebViewDelegate alloc] init];
	
	UIWebView *webView = [[self class] sharedWebView];
	webView.delegate = delegateReflector;	
	
	DNTimerDefine(javascript);
	DNTimerDefine(javascript_decode);
	
	
	NSMutableArray *decodedStuff = [NSMutableArray array];
	DNTimerStart(javascript);
	
	NSString *tet = [NSString stringWithFormat:@"WM_runScriptNamed('%@')", WMJavascript_DEBUG_NAME];
	NSString *outString;
	outString = [webView stringByEvaluatingJavaScriptFromString:tet];

	DNTimerEnd(javascript);
	
	DNTimerStart(javascript_decode);
	NSError *error = nil;
	id outObject = [NSJSONSerialization JSONObjectWithData:[outString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
	
	if ([outObject isKindOfClass:[NSDictionary class]]) {
		[(NSDictionary *)outObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			id decoded = [self decodeObjectFromWMJSAPI:obj];
			[decodedStuff addObject:decoded];
		}];
	}
	DNTimerEnd(javascript_decode);

	NSLog(@"Javascript timing:%@ decode:%@ output:%@", DNTimerGetStringMS(javascript), DNTimerGetStringMS(javascript_decode), outString);
	
	for (id obj in decodedStuff) {
		NSLog(@"decoded: %@", obj);
	}
	
	webView.delegate = nil;
}

@end
