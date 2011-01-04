//
//  EventListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventListController.h"

#import "EventTableViewCell.h"
#import "EventViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "FuzzyDateFormatter.h"

#import "Objects/ServiceProtocol.h"
#import "Objects/EventProtocol.h"

@interface EventListController()
/*!
 @brief start download of event list
 */
- (void)fetchEvents;
/*!
 @brief initiate zap 
 @param sender ui element
 */
- (void)zapAction:(id)sender;
@end

@implementation EventListController

@synthesize dateFormatter = _dateFormatter;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Events", @"Default Title of EventListController");
		_dateFormatter = [[FuzzyDateFormatter alloc] init];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_eventViewController = nil;
		_service = nil;
		_events = [[NSMutableArray array] retain];
		_reloading = NO;
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

	// Set title
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
	[_refreshHeaderView release];

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
	const UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kServiceCellHeight;
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

	// add header view
	EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
	view.delegate = self;
	[self.view addSubview:view];
	_refreshHeaderView = view;
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
	_reloading = YES;
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
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)self.view];
		[(UITableView *)self.view reloadData];
		_reloading = NO;
	}
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

	return indexPath;
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

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
	[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:YES];
}

/* disappeared */
- (void)viewDidDisappear:(BOOL)animated
{
	[_dateFormatter resetReferenceDate];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
#pragma mark -

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	// Clean event list
	[_events removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[(UITableView *)self.view reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_eventXMLDoc release];
	_eventXMLDoc = nil;

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	// we make our live a little easy here, but thats ok for now
	return _reloading;
}

@end
