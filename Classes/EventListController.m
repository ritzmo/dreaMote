//
//  EventListController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventListController.h"

#import "EventTableViewCell.h"
#import "EventViewController.h"
#import "RemoteConnectorObject.h"
#import "Event.h"

@implementation EventListController

@synthesize events = _events;
@synthesize service = _service;

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Events", @"Default Title of EventListController");
	}
	return self;
}

+ (EventListController*)withEventList: (NSArray*) eventList
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.events = [eventList retain];
	eventListController.service = [[Service alloc] init];

	return eventListController;
}

+ (EventListController*)withEventListAndService: (NSArray *) eventList: (Service *)ourService
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.events = [eventList retain];
	eventListController.service = [ourService retain];

	eventListController.title = [ourService sname];

	return eventListController;
}

+ (EventListController*)forService: (Service *)ourService
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.events = [NSMutableArray array];
	eventListController.service = [ourService retain];

	eventListController.title = [ourService sname];

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:eventListController withObject:nil];	

	return eventListController;
}

- (void)dealloc
{
	[_events release];
	[_service release];
	
	[super dealloc];
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 48.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

- (void)fetchEvents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[RemoteConnectorObject sharedRemoteConnector] fetchEPG: self action:@selector(addEvent:) service: [self service]];
	[pool release];
}

- (void)addEvent:(id)event
{
	if(event != nil)
		[_events addObject: [(Event*)event retain]];
	[self reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kEventCell_ID = @"EventCell_ID";

	EventTableViewCell *cell = (EventTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kEventCell_ID];
	if(cell == nil)
	{
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[EventTableViewCell alloc] initWithFrame:cellFrame reuseIdentifier:kEventCell_ID] autorelease];
	}

	cell.event = [_events objectAtIndex:indexPath.row];
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	Event *event = [_events objectAtIndex: indexPath.row];
	EventViewController *eventViewController = [EventViewController withEventAndService: event: _service];
	[[applicationDelegate navigationController] pushViewController: eventViewController animated: YES];

	//[eventViewController release];

	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	// TODO: seperate by day??
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_events count];
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
