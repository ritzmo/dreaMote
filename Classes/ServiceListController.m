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
@synthesize selectTarget = _selectTarget;
@synthesize selectCallback = _selectCallback;
@synthesize justSelecting;

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Services", @"");
		self.services = [NSMutableArray array];
		self.justSelecting = NO;
	}
	return self;
}

- (void)dealloc
{
	[_services release];
	[_selectTarget release];
	
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
	[_services removeAllObjects];

	[[RemoteConnectorObject sharedRemoteConnector] fetchServices:self action:@selector(addService:)];

	[super viewWillAppear: animated];
}

- (void)addService:(id)service
{
	[_services addObject: [(Service*)service retain]];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kServiceCell_ID = @"ServiceCell_ID";

	ServiceTableViewCell *cell = (ServiceTableViewCell*)[tableView dequeueReusableCellWithIdentifier: kServiceCell_ID];
	if(cell == nil)
	{
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[ServiceTableViewCell alloc] initWithFrame: cellFrame reuseIdentifier: kServiceCell_ID] autorelease];
	}

	[cell setService: [[self services] objectAtIndex:indexPath.row]];

	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(justSelecting && _selectTarget != nil && _selectCallback != nil)
	{
		Service *service = [(ServiceTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: indexPath] service];
		[_selectTarget performSelector:(SEL)_selectCallback withObject: service];

		id applicationDelegate = [[UIApplication sharedApplication] delegate];
		
		[[applicationDelegate navigationController] popViewControllerAnimated: YES];
		
		return nil;
	}
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Service Action Title", @"")
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Zap", @""), NSLocalizedString(@"Show EPG", @""), nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
	
	return indexPath; // nil to disable select

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex: (NSInteger)buttonIndex
{
	Service *service = [(ServiceTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] service];

	if (buttonIndex == 0)
	{
		// Second Button: zap
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: service];
	}
	else if (buttonIndex == 1)
	{
		// Third Button: epg
		id applicationDelegate = [[UIApplication sharedApplication] delegate];
		NSMutableArray *eventList = [NSMutableArray array];
		EventListController *eventListController = [EventListController withEventListAndService: eventList: service];
		[[RemoteConnectorObject sharedRemoteConnector] fetchEPG: eventListController action:@selector(addEvent:) service: service];
		[[applicationDelegate navigationController] pushViewController: eventListController animated:YES];
	
		//[eventListController release];
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

- (void)setTarget: (id)target action: (SEL)action
{
	_selectTarget = target;
	_selectCallback = action;
}

@end
