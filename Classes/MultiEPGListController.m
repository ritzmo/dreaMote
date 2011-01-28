//
//  MultiEPGListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

#import "MultiEPGTableViewCell.h"
#import "SwipeTableView.h"

@interface MultiEPGListController()
@property (nonatomic, retain) NSDate *curBegin;
@property (nonatomic, retain) EventViewController *eventViewController;
@end

@implementation MultiEPGListController

- (id)init
{
	if((self = [super init]))
	{
		_epgCache = [EPGCache sharedInstance];
		_events = [[NSMutableDictionary alloc] init];
		_services = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_curBegin release];
	[_events release];
	[_eventViewController release];
	[_services release];
	[_serviceXMLDocument release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	// create table view
	_tableView = [[SwipeTableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// setup our content view so that it auto-rotates along with the UViewController
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kMultiEPGCellHeight;
	_tableView.sectionHeaderHeight = 0;

	self.view = _tableView;

	// add header view
	_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
	_refreshHeaderView.delegate = self;
	[self.view addSubview:_refreshHeaderView];
}

- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_serviceXMLDocument release];
	_reloading = YES;
	_serviceXMLDocument = [[RemoteConnectorObject sharedRemoteConnector] fetchServices:self bouquet:nil isRadio:NO];
	[pool release];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.curBegin = [NSDate date];

	[self fetchData];
	//[_epgCache refreshBouquet:nil delegate:self isRadio:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (NSDate *)curBegin
{
	return _curBegin;
}

- (void)setCurBegin:(NSDate *)now
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit) fromDate:now];
	
	[_curBegin release];
	_curBegin = [[gregorian dateFromComponents:components] retain];
	[gregorian release];
	[_events removeAllObjects];
	[_tableView reloadData];
	
	self.title = [NSString stringWithFormat:@"%.2f", [_curBegin timeIntervalSince1970]];
	self.tabBarItem.title = NSLocalizedString(@"Multi EPG", @"Default title of MultiEPGListController");
	NSDate *twoHours = [_curBegin dateByAddingTimeInterval:60*60*2];
	[_epgCache readEPGForTimeIntervalFrom:_curBegin until:twoHours to:self];
}

- (EventViewController *)eventViewController
{
	if(_eventViewController == nil)
		_eventViewController = [[EventViewController alloc] init];
	return _eventViewController;
}

- (void)setEventViewController:(EventViewController *)new
{
	if(_eventViewController == new) return;

	[_eventViewController release];
	_eventViewController = [new retain];
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	// alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];

	[_tableView reloadData];
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	[_tableView reloadData];
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService:(NSObject <ServiceProtocol>*)service
{
	const NSUInteger idx = _services.count;
	[_services addObject:service];
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent:(NSObject <EventProtocol>*)event
{
	NSMutableArray *arr = [_events valueForKey:event.service.sref];
	if(arr)
	{
		[arr addObject:event];
	}
	else
	{
		arr = [[NSMutableArray alloc] initWithObjects:event, nil];
		[_events setValue:arr forKey:event.service.sref];
		[arr release];
	}
}

#pragma mark -
#pragma mark EPGCacheDelegate
#pragma mark -

- (void)finishedRefreshingCache
{
	// FIXME: implement
	NSDate *twoHours = [_curBegin dateByAddingTimeInterval:60*60*2];
	[_epgCache readEPGForTimeIntervalFrom:_curBegin until:twoHours to:self];
}

#pragma mark -
#pragma mark UITableViewCell
#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const SwipeType lastSwipe = ((SwipeTableView *)_tableView).lastSwipe;
	switch(lastSwipe)
	{
		case swipeTypeRight:
		{
			NSDate *twoHours = [_curBegin dateByAddingTimeInterval:-(60*60*2)];
			self.curBegin = twoHours;
			break;
		}
		case swipeTypeLeft:
		{
			NSDate *twoHours = [_curBegin dateByAddingTimeInterval:60*60*2];
			self.curBegin = twoHours;
			break;
		}
		default:
		{
			const MultiEPGTableViewCell *cell = (MultiEPGTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
			const CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
			const CGPoint lastTouch = ((SwipeTableView *)_tableView).lastTouch;
			CGPoint locationInCell;
			locationInCell.x = lastTouch.x;
			locationInCell.y = lastTouch.y - cellRect.origin.y;
			NSObject<EventProtocol> *event = [cell eventAtPoint:locationInCell];
			EventViewController *eventViewController = self.eventViewController;
			eventViewController.event = event;
			eventViewController.service = cell.service;

			[self.navigationController pushViewController:eventViewController animated:YES];
			break;
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MultiEPGTableViewCell *cell = (MultiEPGTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kMultiEPGCell_ID];
	if(cell == nil)
		cell = [[[MultiEPGTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMultiEPGCell_ID] autorelease];

	NSObject<ServiceProtocol> *service = [_services objectAtIndex:indexPath.row];
	cell.service = service;
	cell.begin = _curBegin;
	cell.events = [_events valueForKey:service.sref];

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_services count];
}

@end
