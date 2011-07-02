//
//  MultiEPGListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGListController.h"

#import "AppDelegate.h"
#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "MultiEPGHeaderView.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"

#import "MultiEPGTableViewCell.h"

@interface MultiEPGListController()
/*!
 @brief Setup and assign toolbar items.
 */
- (void)configureToolbar;

/*!
 @brief Refresh "now" timestamp and take care of timer.
 */
- (void)refreshNow;

/*!
 @brief Entry point for thread fetching events from database.
 */
- (void)readEPG;

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
		_secondsSinceBegin = -1;
		_servicesToRefresh = -1;
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
	const CGFloat headerHeight = (IS_IPAD()) ? kMultiEPGHeaderHeightIpad : kMultiEPGCellHeight;

	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view = contentView;
	CGRect visibleFrame = CGRectMake(0, headerHeight, contentView.frame.size.width, contentView.frame.size.height-headerHeight);
	_tableView.frame = visibleFrame;
	[contentView addSubview:_tableView];

	_headerView = [[MultiEPGHeaderView alloc] initWithFrame:CGRectMake(0, 0, contentView.frame.size.width, headerHeight)];
	[contentView addSubview:_headerView];

	[self configureToolbar];
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
	[progressHUD setDetailsLabelText:NSLocalizedString(@"This can take a while.", @"Details label of Progress HUD in MultiEPG. Since loading the EPG for an entire bouquet took me about 5minutes over WiFi this warning is appropriate.")];
	[progressHUD setMode:MBProgressHUDModeDeterminate];
	progressHUD.progress = 0.0f;
	[progressHUD show:YES];
	progressHUD.taskInProgress = YES;

	_servicesToRefresh = -1;
	_reloading = YES;
	++pendingRequests;
	[_epgCache refreshBouquet:_bouquet delegate:self isRadio:NO];
	[pool release];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	NSDate *newBegin = nil;
	if(!_willReapper)
	{
		// reset visible area to to "now"
		newBegin = [NSDate date];
	}
	else
	{
		// don't change visible area, but reload event data
		newBegin = _curBegin;
	}
	self.curBegin = newBegin;

	_willReapper = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
	const CGFloat headerHeight = (IS_IPAD()) ? 40 : kMultiEPGCellHeight;
	_headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, headerHeight);
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(!_willReapper)
	{
		[_refreshTimer invalidate];
		_refreshTimer = nil;
	}
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
	++pendingRequests;
	// Same bouquet assigned, abort
	if(_bouquet == new) return;

	// Free old bouquet, retain new one
	[_bouquet release];
	_bouquet = [new copy];

	// Free Caches and reload data
	[self emptyData];
	_reloading = YES;
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	if([self.view superview])
		self.curBegin = [NSDate date];

	// NOTE: We let the ServiceList passively refresh our data, so just die here
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
	_headerView.begin = _curBegin;

	[self refreshNow];

	++pendingRequests;
	[NSThread detachNewThreadSelector:@selector(readEPG) toTarget:self withObject:nil];
}

/* getter of willReapper */
- (BOOL)willReappear
{
	return _willReapper;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_events count]) _willReapper = new;
}

/* go back two hours in time */
- (void)backButtonPressed:(id)sender
{
	NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
	NSDate *until = [_curBegin dateByAddingTimeInterval:-[timeInterval floatValue]];
	self.curBegin = until;
}

/* go forward two hours in time */
- (void)forwardButtonPressed:(id)sender
{
	NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
	NSDate *until = [_curBegin dateByAddingTimeInterval:[timeInterval floatValue]];
	self.curBegin = until;
}

/* go to current hour */
- (void)nowButtonPressed:(id)sender
{
	self.curBegin = [NSDate date];
}

/* go to 20:00 */
- (void)primetimeButtonPressed:(id)sender
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit) fromDate:_curBegin];
	[components setHour: 20];
	self.curBegin = [gregorian dateFromComponents:components];
	[gregorian release];
}

/* setup toolbar */
- (void)configureToolbar
{
	// XXX: use Rewind/FFwd SystemItems for back/forward? Check HIG!
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"<<"
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(backButtonPressed:)];
	UIBarButtonItem *nowButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Now", @"MultiEPG change to current hour")
																  style:UIBarButtonItemStyleBordered
																 target:self
																 action:@selector(nowButtonPressed:)];

	// flex item used to separate the left groups items and right grouped items
	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];

	UIBarButtonItem *primetimeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Primetime", @"MultiEPG change to 20:00")
																		style:UIBarButtonItemStyleBordered
																	   target:self
																	   action:@selector(primetimeButtonPressed:)];
	UIBarButtonItem *fwdButton = [[UIBarButtonItem alloc] initWithTitle:@">>"
																  style:UIBarButtonItemStyleBordered
																 target:self
																 action:@selector(forwardButtonPressed:)];

	NSArray *items = [[NSArray alloc] initWithObjects:backButton, nowButton, flexItem, primetimeButton, fwdButton, nil];
	[self setToolbarItems:items animated:NO];

	[items release];
	[fwdButton release];
	[primetimeButton release];
	[flexItem release];
	[nowButton release];
	[backButton release];
}

/* refresh "now" timestamp */
- (void)refreshNow
{
	// create timer
	if(_refreshTimer == nil)
	{
		_refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60
														 target:self
													   selector:@selector(refreshNow)
													   userInfo:nil
														repeats:YES];
	}

	// check if we are in visible timespan
	NSDate *now = [[NSDate alloc] init];
	_secondsSinceBegin = [now timeIntervalSinceDate:_curBegin];
	[now release];
	if(_secondsSinceBegin > 0 && _secondsSinceBegin < 60*60*2)
	{
		[_tableView reloadData];
	}
	else
	{
		_secondsSinceBegin = -1;
	}
}

/* entry point for thread fetching epg entries */
- (void)readEPG
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	@synchronized(self)
	{
		NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
		NSDate *until = [_curBegin dateByAddingTimeInterval:[timeInterval floatValue]];
		[_epgCache readEPGForTimeIntervalFrom:_curBegin until:until to:self];
	}

	[pool release];
}

/* did rotate */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

	// TODO: rotate with rest of the screen
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.1f];
	const CGFloat headerHeight = (IS_IPAD()) ? 40 : kMultiEPGCellHeight;
	_headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, headerHeight);
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate methods
#pragma mark -

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	if(_reloading) return;

	const UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Really %@?", @"Confirmation dialog title"), NSLocalizedString(@"refresh EPG", "used in confirmation dialog: really refresh epg?")]
																   delegate:self
														  cancelButtonTitle:NSLocalizedString(@"Cancel", "")
													 destructiveButtonTitle:NSLocalizedString(@"Refresh", "")
														  otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	if(self.tabBarController == nil)
		[actionSheet showFromTabBar:APP_DELEGATE.tabBarController.tabBar];
	else
		[actionSheet showFromTabBar:self.tabBarController.tabBar];
	[actionSheet release];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == actionSheet.destructiveButtonIndex)
	{
		[self emptyData];

		// Spawn a thread to fetch the event data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	}
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
	[_services addObject:service];
#if INCLUDE_FEATURE(Extra_Animation)
	const NSUInteger idx = _services.count-1;
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
#endif
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

	_servicesToRefresh = -1;
	_reloading = NO;

	[NSThread detachNewThreadSelector:@selector(readEPG) toTarget:self withObject:nil];
}

- (void)remainingServicesToRefresh:(NSNumber *)count
{
	if(_servicesToRefresh == -1)
		_servicesToRefresh = [count integerValue];
	progressHUD.progress = 1 - ([count integerValue] / _servicesToRefresh);
}

#pragma mark -
#pragma mark SwipeTableViewDelegate
#pragma mark -

- (void)tableView:(SwipeTableView *)tableView didSwipeRowAtIndexPath:(NSIndexPath *)indexPath
{
	// only detect left&right swipes
	const SwipeType lastSwipe = _tableView.lastSwipe & (swipeTypeLeft | swipeTypeRight);
	switch(lastSwipe)
	{
		case swipeTypeRight:
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			NSDate *until = [_curBegin dateByAddingTimeInterval:-[timeInterval floatValue]];
			self.curBegin = until;
			break;
		}
		case swipeTypeLeft:
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			NSDate *until = [_curBegin dateByAddingTimeInterval:[timeInterval floatValue]];
			self.curBegin = until;
			break;
		}
		default: break;
	}
}

#pragma mark -
#pragma mark UITableView
#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(IS_IPAD())
	{
		return kMultiEPGCellHeightIpad;
	}
	else
	{
		NSObject<ServiceProtocol> *service = [_services objectAtIndex:indexPath.row];
		if(service.picon)
			return kMultiEPGCellHeightPicon;
	}
	return kMultiEPGCellHeight;
}

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
	MultiEPGTableViewCell *cell = [MultiEPGTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMultiEPGCell_ID];

	NSObject<ServiceProtocol> *service = [_services objectAtIndex:indexPath.row];
	cell.service = service;
	cell.begin = _curBegin;
	cell.events = [_events valueForKey:service.sref];
	cell.secondsSinceBegin = _secondsSinceBegin;

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_services count];
}

#if 0
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	const NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	NSString *firstString = [format fuzzyDate:_curBegin];
	[format setDateStyle:NSDateFormatterNoStyle];
	NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
	NSDate *until = [_curBegin dateByAddingTimeInterval:[timeInterval floatValue]];
	NSString *secondString = [format fuzzyDate:until];
	[format release];
	return [NSString stringWithFormat:@"%@ - %@", firstString, secondString];
}
#endif

@end
