//
//  WMDebugViewController.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMDebugViewController.h"

#import "WMEngine.h"
#import "WMViewController.h"
#import "BrowserViewController.h"

#import <netinet/in.h>
#import <arpa/inet.h>

@implementation WMDebugViewController

@synthesize parent;
@synthesize activityIndicator;
@synthesize gameTitleLabel;
@synthesize gamePathLabel;


- (void)updateLabels;
{
	gameTitleLabel.text = [parent.engine title];
//	gamePathLabel.text = [parent.engine.assetManager.assetBundle bundlePath];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self updateLabels];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.gamePathLabel = nil;
	self.gameTitleLabel = nil;
}

- (IBAction)close;
{
	[self.view removeFromSuperview];
}

- (IBAction)reloadGame;
{
	[activityIndicator startAnimating];
	[parent reloadGame];
	[activityIndicator stopAnimating];
}


#pragma mark -
#pragma mark Remote loading

- (NSString *)hostFromAddress4:(const struct sockaddr_in *)pSockaddr4
{
	char addrBuf[INET_ADDRSTRLEN];
	
	if(inet_ntop(AF_INET, &pSockaddr4->sin_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
	{
		[NSException raise:NSInternalInconsistencyException format:@"Cannot convert IPv4 address to string."];
	}
	
	return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

- (NSString *)hostFromAddress6:(const struct sockaddr_in6 *)pSockaddr6
{
	char addrBuf[INET6_ADDRSTRLEN];
	
	if(inet_ntop(AF_INET6, &pSockaddr6->sin6_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
	{
		[NSException raise:NSInternalInconsistencyException format:@"Cannot convert IPv6 address to string."];
	}
	
	return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

- (void) browserViewController:(BrowserViewController *)bvc didResolveInstance:(NSNetService *)netService;
{
	[bvc.view removeFromSuperview];
	
	
	NSString *addr = nil;
	for (NSData *data in [netService addresses]) {
		if (!addr && data.length == sizeof(struct sockaddr_in)) {
			addr = [self hostFromAddress4:[data bytes]];
		} else if (!addr && data.length == sizeof(struct sockaddr_in6)) {
			addr = [self hostFromAddress6:[data bytes]];
		}
	}
	NSLog(@"Picked net service: %@ (%@)", netService, addr);
	
	NSString *path = @"/";
	NSURL *bundleURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d%@", addr, [netService port], path]];
	
	NSLog(@"Will try to load bundle from url: %@", bundleURL);
	[parent reloadGameFromURL:bundleURL];
}

- (IBAction)loadRemote;
{
	BrowserViewController *browser = [[BrowserViewController alloc] initWithTitle:@"Pick Source" showDisclosureIndicators:YES showCancelButton:YES];
	browser.delegate = self;
	[browser searchForServicesOfType:@"_wmremote._tcp" inDomain:@"local"];
	browser.view.frame = self.view.bounds;
	[self.view addSubview:browser.view];
}

#pragma mark -

- (void)dealloc {
	[gamePathLabel release];
	[gameTitleLabel release];
    [super dealloc];
}


@end
