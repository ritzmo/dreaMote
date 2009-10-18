//
//  EventListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventListController.h"

#import "EventTableViewCell.h"
#import "EventViewController.h"

#import "RemoteConnectorObject.h"
#import "FuzzyDateFormatter.h"

#import "Objects/ServiceProtocol.h"
#import "Objects/EventProtocol.h"

@implementation EventListController

@synthesize dateFormatter = _dateFormatter;

/* initialize */
- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Events", @"Default Title of EventListController");
		_dateFormatter = [[FuzzyDateFormatter alloc] init];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_eventViewController = nil;
		_service = nil;
		_events = [[NSMutableArray array] retain];
	}
	return self;
}

/* new list for given service */
+ (EventListController*)forService: (NSObject<ServiceProtocol> *)ourService
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.service = ourService;

	return [eventListController autorelease];
}

/* getter for service property */
- (NSObject<ServiceProtocol> *)service
{
	return _service;
}

/* setter for service property */
- (void)setService: (NSObject<ServiceProtocol> *)newService
{
	// No change, return immediately
	if(_service == newService) return;

	// Free old service, assign new
	[_service release];
	_service = [newService retain];

	// Set tigle
	self.title = newService.sname;

	// Clean event list
	[_events removeAllObjects];
	[(UITableView *)self.view reloadData];
	[_eventXMLDoc release];
	_eventXMLDoc = nil;

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];
}

/* dealloc */
- (void)dealloc
{
	[_events release];
	[_service release];
	[_dateFormatter release];
	[_eventViewController release];
	[_eventXMLDoc release];

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	[_eventViewController release];
	_eventViewController = nil;
	
    [super didReceiveMemoryWarning];
}

/* layout */
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

	// Create zap button
	UIBarButtonItem *zapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zap", @"") style:UIBarButtonItemStylePlain target:self action:@selector(zapAction:)];
	self.navigationItem.rightBarButtonItem = zapButton;
	[zapButton release];
}

/* zap */
- (void)zapAction:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
}

/* start download of event list */
- (void)fetchEvents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_eventXMLDoc release];
	_eventXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchEPG: self service: _service] retain];
	[pool release];
}

/* add event to list */
- (void)addEvent: (NSObject<EventProtocol> *)event
{
	if(event != nil)
	{
		[_events addObject: event];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_events count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
	[(UITableView *)self.view reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	EventTableViewCell *cell = (EventTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kEventCell_ID];
	if(cell == nil)
		cell = [[[EventTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kEventCell_ID] autorelease];

	cell.formatter = _dateFormatter;
	cell.showService = NO;
	cell.event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<EventProtocol> *event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];

	if(_eventViewController == nil)
		_eventViewController = [[EventViewController alloc] init];

	_eventViewController.event = event;
	_eventViewController.service = _service;

	[self.navigationController pushViewController: _eventViewController animated: YES];

	return nil;
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	// TODO: seperate by day??
	return 1;
}

/* number of items */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_events count];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/* disappeared */
- (void)viewDidDisappear:(BOOL)animated
{
	[_dateFormatter resetReferenceDate];
}

@end
