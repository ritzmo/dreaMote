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
#import "RemoteConnectorObject.h"
#import "Service.h"

@implementation ServiceListController

@synthesize services = _services;
@synthesize selectTarget = _selectTarget;
@synthesize selectCallback = _selectCallback;
@synthesize refreshServices = _refreshServices;

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Services", @"");
		self.services = [NSMutableArray array];
		self.refreshServices = YES;
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
	// Spawn a thread to fetch the service data so that the UI is not blocked while the
	// application parses the XML file.
	if(_refreshServices)
		[NSThread detachNewThreadSelector:@selector(fetchServices) toTarget:self withObject:nil];

	_refreshServices = YES;

	[super viewWillAppear: animated];
}

- (void)fetchServices
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_services removeAllObjects];

	[self reloadData];

	[[RemoteConnectorObject sharedRemoteConnector] fetchServices:self action:@selector(addService:)];
	[pool release];
}

- (void)addService:(id)service
{
	if(service != nil)
		[_services addObject: [(Service*)service retain]];
	[self reloadData];
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

	[cell setService: [_services objectAtIndex:indexPath.row]];

	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_selectTarget != nil && _selectCallback != nil)
	{
		Service *service = [_services objectAtIndex: indexPath.row];
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
		EventListController *eventListController = [EventListController forService: service];

		[[applicationDelegate navigationController] pushViewController: eventListController animated:YES];
	
		//[eventListController release];
		
		_refreshServices = NO;
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
	return [_services count];
}

- (void)setTarget: (id)target action: (SEL)action
{
	_selectTarget = target;
	_selectCallback = action;
}

@end
