//
//  ServiceListController.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceListController.h"

#import "EventListController.h"

#import "ServiceTableViewCell.h"
#import "AppDelegateMethods.h"
#import "RemoteConnectorObject.h"
#import "Service.h"

@implementation ServiceListController

@synthesize services = _services;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Services", @"");
		self.services = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
	[_services release];
	
	[super dealloc];
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
    tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 38.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	
	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_services release];
	_services = [[[RemoteConnectorObject sharedRemoteConnector] fetchServices] retain];

	[super viewWillAppear: animated];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath withAvailableCell:(UITableViewCell *)availableCell {
	ServiceTableViewCell *cell = nil;
	if (availableCell != nil) {
		cell = (ServiceTableViewCell *)availableCell;
	} else {
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[ServiceTableViewCell alloc] initWithFrame:cellFrame] autorelease];
	}

	cell.service = [[self services] objectAtIndex:indexPath.row];
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Service Action Title", @"") message:NSLocalizedString(@"Service Action Message", @"")
									delegate:self defaultButton:nil cancelButton:NSLocalizedString(@"Cancel", @"") otherButtons:NSLocalizedString(@"Zap", @""), NSLocalizedString(@"Show EPG", @""), nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
	
	return indexPath; // nil to disable select

}

- (void)modalView:(UIModalView *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	Service *service = [(ServiceTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] service];

	if (buttonIndex == 1)
	{
		// Second Button: zap
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: service];
	}
	else if (buttonIndex == 2)
	{
		// Third Button: epg
		id applicationDelegate = [[UIApplication sharedApplication] delegate];
		NSArray *eventList = [[RemoteConnectorObject sharedRemoteConnector] fetchEPG: service];
		EventListController *eventListController = [EventListController withEventList: eventList];
		[[applicationDelegate navigationController] pushViewController: eventListController animated:YES];
		
		[eventListController release];
	}

	NSIndexPath *tableSelection = [(UITableView*)self.view indexPathForSelectedRow];
	[(UITableView*)self.view deselectRowAtIndexPath:tableSelection animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	// TODO: handle seperators?
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [[self services] count];
}

@end
