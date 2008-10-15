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
@synthesize dateFormatter;

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Events", @"Default Title of EventListController");
		dateFormatter = [[FuzzyDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		eventViewController = nil;
	}
	return self;
}

+ (EventListController*)withEventListAndService: (NSArray *) eventList: (Service *)ourService
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.events = eventList;
	eventListController.service = ourService;

	eventListController.title = ourService.sname;

	return eventListController;
}

+ (EventListController*)forService: (Service *)ourService
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.events = [NSMutableArray array];
	eventListController.service = ourService;

	eventListController.title = ourService.sname;

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:eventListController withObject:nil];	

	return eventListController;
}

- (void)dealloc
{
	[_events makeObjectsPerformSelector:@selector(release)];
	[_events release];
	[_service release];
	[dateFormatter release];
	[eventViewController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[eventViewController release];
	eventViewController = nil;
	
    [super didReceiveMemoryWarning];
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
	[[RemoteConnectorObject sharedRemoteConnector] fetchEPG: self action:@selector(addEvent:) service: _service];
	[pool release];
}

- (void)addEvent:(id)event
{
	if(event != nil)
	{
		[(NSMutableArray *)_events addObject: (Event*)event];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_events count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
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
		cell = [[[EventTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kEventCell_ID] autorelease];

	cell.formatter = dateFormatter;
	cell.event = [_events objectAtIndex:indexPath.row];
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Event *event = [_events objectAtIndex: indexPath.row];
	if(eventViewController == nil)
		eventViewController = [[EventViewController alloc] init];

	eventViewController.event = event;
	eventViewController.service = _service;

	[self.navigationController pushViewController: eventViewController animated: YES];

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

- (void)viewDidDisappear:(BOOL)animated
{
	[eventViewController release];
	eventViewController = nil;
}

@end
