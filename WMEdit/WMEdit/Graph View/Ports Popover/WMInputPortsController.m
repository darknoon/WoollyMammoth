//
//  WMInputPortsController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMInputPortsController.h"

#import "WMPorts.h"

#import "WMInputPortCell.h"
#import "WMNumberInputPortCell.h"
#import "WMIndexInputPortCell.h"
#import "WMBooleanInputPortCell.h"

@implementation WMInputPortsController
@synthesize ports;

- (id)init;
{
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	for (NSString *nibName in [NSArray arrayWithObjects:@"WMNumberInputPortCell", @"WMBooleanInputPortCell", @"WMIndexInputPortCell", @"WMInputPortCell", nil]) {
		[self.tableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:nibName];
	}
    
	[super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
	return ports.count;
}

- (CGSize)contentSizeForViewInPopover;
{
	return (CGSize){.width = 400, .height = self.ports.count * (self.tableView ? self.tableView.rowHeight : 44.f)};
}

- (Class)portCellClassForPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMNumberPort class]]) {
		return [WMNumberInputPortCell class];
	} else if ([inPort isKindOfClass:[WMBooleanPort class]]) {
		return [WMBooleanInputPortCell class];
	} else if ([inPort isKindOfClass:[WMIndexPort class]]) {
		return [WMIndexInputPortCell class];
	} else {
		return [WMInputPortCell class];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	WMPort *port = [ports objectAtIndex:indexPath.row];
	
    NSString *cellIdentifier = NSStringFromClass([self portCellClassForPort:port]);
    
    WMInputPortCell *cell = (WMInputPortCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.nameLabel.text = port.name;
	cell.port = port;
    
    return cell;
}


@end
