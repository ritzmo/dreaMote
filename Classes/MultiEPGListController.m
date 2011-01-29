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
#import "NSDateFormatter+FuzzyFormatting.h"

#import "MultiEPGTableViewCell.h"

@interface MultiEPGListController()
/*!
 @brief Activity Indicator.
 */
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@end

@implementation MultiEPGListController

@synthesize multiEpgDelegate = _mepgDelegate;
@synthesize progressHUD;

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
	[_services release];
	[_serviceXMLDocument release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kMultiEPGCellHeight;
}


- (void)emptyData
{
	[_services removeAllObjects];
	[_events removeAllObjects];
	[_tableView reloadData];
	[_serviceXMLDocument release];
	_serviceXMLDocument = nil;
}

- (void)fetchServices
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_serviceXMLDocument release];
	_reloading = YES;
	++pendingRequests;
	_serviceXMLDocument = [[RemoteConnectorObject sharedRemoteConnector] fetchServices:self bouquet:_bouquet isRadio:NO];
	[pool release];
}

- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread detachNewThreadSelector:@selector(fetchServices) toTarget:self withObject:nil];

	progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview: progressHUD];
	progressHUD.delegate = self;
	[progressHUD setLabelText:NSLocalizedString(@"Loading EPG…", @"Label of Progress HUD in MultiEPG")];
	[progressHUD show:YES];
	progressHUD.taskInProgress = YES;

	_reloading = YES;
	++pendingRequests;
	[_epgCache refreshBouquet:_bouquet delegate:self isRadio:NO];
	[pool release];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	// reset visible area to to "now"
	self.curBegin = [NSDate date];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

/* getter for bouquet property */
- (NSObject<ServiceProtocol> *)bouquet
{
	return _bouquet;
}

/* setter for bouquet property */
- (void)setBouquet: (NSObject<ServiceProtocol> *)new
{
	// Same bouquet assigned, abort
	if(_bouquet != nil && _bouquet == new) return;

	// Free old bouquet, retain new one
	[_bouquet release];
	_bouquet = [new copy];

	// Free Caches and reload data
	_reloading = YES;
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	self.curBegin = [NSDate date];

	++pendingRequests;
	// NOTE: We let the ServiceList passively refresh our data, so just die hiere
}

/* getter of curBegin property */
- (NSDate *)curBegin
{
	return _curBegin;
}

/* setter of curBegin property */
- (void)setCurBegin:(NSDate *)now
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit) fromDate:now];
	
	[_curBegin release];
	_curBegin = [[gregorian dateFromComponents:components] retain];
	[gregorian release];
	[_events removeAllObjects];
	[_tableView reloadData];

	NSDate *twoHours = [_curBegin dateByAddingTimeInterval:60*60*2];
	++pendingRequests;
	[_epgCache readEPGForTimeIntervalFrom:_curBegin until:twoHours to:self];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate
#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[progressHUD removeFromSuperview];
	self.progressHUD = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	if(--pendingRequests == 0)
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
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	if(--pendingRequests == 0)
	{
		[_tableView reloadData];
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	}
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
	progressHUD.taskInProgress = NO;
	[progressHUD hide:YES];

	_reloading = NO;
	NSDate *twoHours = [_curBegin dateByAddingTimeInterval:60*60*2];
	[_epgCache readEPGForTimeIntervalFrom:_curBegin until:twoHours to:self];
}

#pragma mark -
#pragma mark SwipeTableViewDelegate
#pragma mark -

- (void)tableView:(SwipeTableView *)tableView didSwipeRowAtIndexPath:(NSIndexPath *)indexPath
{
	const SwipeType lastSwipe = _tableView.lastSwipe;
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
		default: break;
	}
}

#pragma mark -
#pragma mark UITableView
#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const MultiEPGTableViewCell *cell = (MultiEPGTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	const CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
	const CGPoint lastTouch = _tableView.lastTouch;
	CGPoint locationInCell;
	locationInCell.x = lastTouch.x;
	locationInCell.y = lastTouch.y - cellRect.origin.y;
	NSObject<EventProtocol> *event = [cell eventAtPoint:locationInCell];
	[_mepgDelegate multiEPG:self didSelectEvent:event onService:cell.service];

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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	const NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	NSString *firstString = [format fuzzyDate:_curBegin];
	[format setDateStyle:NSDateFormatterNoStyle];
	NSString *secondString = [format fuzzyDate:[_curBegin dateByAddingTimeInterval:60*60*2]];
	[format release];
	return [NSString stringWithFormat:@"%@ - %@", firstString, secondString];
}

@end
