//
//  MultiEPGListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "MultiEPGListController.h"

#import "AppDelegate.h"
#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "MultiEPGHeaderView.h"

#import "NSDateFormatter+FuzzyFormatting.h"
#import "UIDevice+SystemVersion.h"
#import "UITableViewCell+EasyInit.h"

#import <ListController/ServiceZapListController.h>
#import <ListController/SimpleSingleSelectionListController.h>

#import <ViewController/AutoTimerViewController.h>
#import <ViewController/TimerViewController.h>

#import <TableViewCell/MultiEPGTableViewCell.h>

#import <Objects/Generic/AutoTimer.h>
#import <Objects/Generic/Result.h>
#import <Objects/Generic/Timer.h>

#import <XMLReader/SaxXmlReader.h>

#pragma mark - UIActionSheet with block callback
typedef void (^dismiss_block_t)(UIActionSheet *actionSheet, NSInteger buttonIndex);
@interface UIBlockActionSheet : UIActionSheet<UIActionSheetDelegate>
+ (UIBlockActionSheet *)actionSheetWithTitle:(NSString *)title
						   cancelButtonTitle:(NSString *)cancelButtonTitle
					  destructiveButtonTitle:(NSString *)destructiveButtonTitle
						   otherButtonTitles:(NSArray *)buttonTitles
								   onDismiss:(dismiss_block_t)onDismiss;
@property (nonatomic, copy) dismiss_block_t onDismiss;
@end

@implementation UIBlockActionSheet
@synthesize onDismiss;
+ (UIBlockActionSheet *)actionSheetWithTitle:(NSString *)title
						   cancelButtonTitle:(NSString *)cancelButtonTitle
					  destructiveButtonTitle:(NSString *)destructiveButtonTitle
						   otherButtonTitles:(NSArray *)buttonTitles
								   onDismiss:(dismiss_block_t)onDismiss
{
	UIBlockActionSheet *sheet = [[UIBlockActionSheet alloc] initWithTitle:title
																 delegate:nil
														cancelButtonTitle:nil
												   destructiveButtonTitle:destructiveButtonTitle
														otherButtonTitles:nil];

	for(NSString* thisButtonTitle in buttonTitles)
		[sheet addButtonWithTitle:thisButtonTitle];

	if(cancelButtonTitle)
	{
		[sheet addButtonWithTitle:cancelButtonTitle];
		sheet.cancelButtonIndex = [buttonTitles count];

		if(destructiveButtonTitle)
			sheet.cancelButtonIndex++;
	}
	sheet.onDismiss = onDismiss;
	sheet.delegate = sheet;
	return sheet;
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	((UIBlockActionSheet *)actionSheet).onDismiss(actionSheet, buttonIndex);
}
@end

#pragma mark - MultiEPGListController

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
 @brief Event was/is being held.
 */
- (void)longPress:(UILongPressGestureRecognizer *)gesture;

/*!
 @brief Activity Indicator.
 */
@property (nonatomic, strong) MBProgressHUD *progressHUD;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, strong) UIPopoverController *popoverController;

/*!
 @brief Zap type selection.
 */
@property (nonatomic, strong) ServiceZapListController *zapListController;
@end

@implementation MultiEPGListController

@synthesize multiEpgDelegate;
@synthesize pendingRequests;
@synthesize progressHUD;
@synthesize isSlave;
@synthesize popoverController;
@synthesize zapListController;

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
	progressHUD.delegate = nil;
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

	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[_tableView addGestureRecognizer:longPressGesture];

	_headerView = [[MultiEPGHeaderView alloc] initWithFrame:CGRectMake(0, 0, contentView.frame.size.width, headerHeight)];
	[contentView addSubview:_headerView];

	[self configureToolbar];
	[self theme];
}

- (void)theme
{
	[super theme];
	_headerView.backgroundColor = _tableView.backgroundColor;
	self.view.backgroundColor = _tableView.backgroundColor;
	[_headerView theme];
}

- (void)viewDidUnload
{
	_tableView.tableHeaderView = nil;
	_headerView = nil;

	[super viewDidUnload];
}

- (void)emptyData
{
	[_services removeAllObjects];
	[_events removeAllObjects];
	[_tableView reloadData];
	_xmlReader = nil;
}

- (void)fetchData
{
	@autoreleasepool
	{
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
	}
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	if(![EPGCache sharedInstance].reloading)
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
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	const CGFloat headerHeight = (IS_IPAD()) ? 40 : kMultiEPGCellHeight;
	_headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, headerHeight);
	[super viewDidAppear:animated];
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(!_willReapper)
	{
		NSTimer *timer = _refreshTimer;
		_refreshTimer = nil;
		[timer invalidate];
	}
	[super viewWillDisappear:animated];
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

	_curBegin = [gregorian dateFromComponents:components];
	[_events removeAllObjects];
	[_tableView reloadData];
	_headerView.begin = _curBegin;

	[self refreshNow];

	++pendingRequests;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self readEPG]; });
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
}

/* setup toolbar */
- (void)configureToolbar
{
	// XXX: use Rewind/FFwd SystemItems for back/forward? Check HIG!
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"<<"
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(backButtonPressed:)];
	backButton.accessibilityLabel = NSLocalizedString(@"Previous page", @"Accessibility text of 'back' button in MultiEPG");
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
	fwdButton.accessibilityLabel = NSLocalizedString(@"Next page", @"Accessibility text of 'next' button in MultiEPG");

	NSArray *items = [[NSArray alloc] initWithObjects:backButton, nowButton, flexItem, primetimeButton, fwdButton, nil];
	[self setToolbarItems:items animated:NO];

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
	[_tableView reloadData];
}

/* entry point for thread fetching epg entries */
- (void)readEPG
{
	@autoreleasepool {

		@synchronized(self)
		{
			NSDate *begin = _curBegin;
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			NSDate *until = [begin dateByAddingTimeInterval:[timeInterval floatValue]];
			[_epgCache readEPGForTimeIntervalFrom:begin until:until to:self];
		}

	}
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
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == actionSheet.destructiveButtonIndex)
	{
		[self emptyData];

		// NOTE: not running from our queue as we don't want this to be canceled
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self fetchData]; });
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

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	if(dataSource == _xmlReader)
		_xmlReader = nil;

	if(--pendingRequests == 0)
	{
		// alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
															  message:[error localizedDescription]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];

		[_tableView reloadData];
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	}
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	if(dataSource == _xmlReader)
		_xmlReader = nil;

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
	if(!service)
		return;

	[_services addObject:service];
#if INCLUDE_FEATURE(Extra_Animation)
	const NSUInteger idx = _services.count-1;
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
#endif
}

- (void)addServices:(NSArray *)items
{
#if INCLUDE_FEATURE(Extra_Animation)
	NSUInteger count = _services.count;
	NSMutableArray *indexPaths = (self.isViewLoaded && [self.view superview]) ? [NSMutableArray arrayWithCapacity:items.count] : nil;
#endif
	[_services addObjectsFromArray:items];
#if INCLUDE_FEATURE(Extra_Animation)
	for(NSObject<ServiceProtocol> *service in items)
	{
		[indexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];
		++count;
	}
#endif
#if INCLUDE_FEATURE(Extra_Animation)
	if(indexPaths)
		[_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
	else
	{
		[_tableView reloadData];
	}
#endif
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent:(NSObject <EventProtocol>*)event
{
	if(!event || !event.service.sref)
	{
#if IS_DEBUG()
		NSLog(@"[MultiEPGListController] Got nil-Event or nil sref in addEvent: %@ // %@", event, event.service.sref);
#endif
		return;
	}

	NSMutableArray *arr = [_events valueForKey:event.service.sref];
	if(arr)
	{
		[arr addObject:event];
	}
	else
	{
		arr = [[NSMutableArray alloc] initWithObjects:event, nil];
		[_events setValue:arr forKey:event.service.sref];
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

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self readEPG]; });
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
	NSTimeInterval interval = 0;
	switch(lastSwipe)
	{
		case swipeTypeRight:
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			interval = -[timeInterval floatValue];
			break;
		}
		case swipeTypeLeft:
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			interval = [timeInterval floatValue];
			break;
		}
		default: break;
	}

	if(interval)
	{
		NSDate *until = [_curBegin dateByAddingTimeInterval:interval];
		self.curBegin = until;
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
	else if(self.isViewLoaded && [self.view superview])
	{
		NSObject<ServiceProtocol> *service = [_services objectAtIndex:indexPath.row];
		if(service.picon)
			return kMultiEPGCellHeightPicon;
	}
	return kMultiEPGCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		[NSException raise:@"MultiEPGListUserInteractionWhileReloading" format:@"willSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return;
	}

	const MultiEPGTableViewCell *cell = (MultiEPGTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	const CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
	const CGPoint lastTouch = _tableView.lastTouch;
	CGPoint locationInCell;
	locationInCell.x = lastTouch.x;
	locationInCell.y = lastTouch.y - cellRect.origin.y;
	NSObject<EventProtocol> *event = [cell eventAtPoint:locationInCell];
	if([multiEpgDelegate respondsToSelector:@selector(multiEPG:didSelectEvent:onService:)])
		[multiEpgDelegate multiEPG:self didSelectEvent:event onService:cell.service];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MultiEPGTableViewCell *cell = [MultiEPGTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMultiEPGCell_ID];

	NSObject<ServiceProtocol> *service = [_services objectAtIndex:indexPath.row];
	cell.service = service;
	cell.epgView.begin = _curBegin;
	cell.epgView.events = [_events valueForKey:service.sref];
	cell.epgView.secondsSinceBegin = _secondsSinceBegin;

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave];
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_services count];
}

#pragma mark Gestures

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
	// only do something on gesture start
	if(gesture.state != UIGestureRecognizerStateBegan)
		return;

	const CGPoint p = [gesture locationInView:_tableView];
	NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:p];
	const MultiEPGTableViewCell *cell = (MultiEPGTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
	const CGRect cellRect = [_tableView rectForRowAtIndexPath:indexPath];
	const CGPoint lastTouch = _tableView.lastTouch;
	CGPoint locationInCell;
	locationInCell.x = lastTouch.x;
	locationInCell.y = lastTouch.y - cellRect.origin.y;
	NSObject<EventProtocol> *event = [cell eventAtPoint:locationInCell];
	NSObject<ServiceProtocol> *service = cell.service;

	// check for invalid service and invalid event (can the latter happen?)
	if(!service || !service.valid || (event && !event.valid))
		return;

	// event selected
	if(event)
	{
		void (^timer_function)(NSInteger selection) = ^(NSInteger selection)
		{
			switch(selection)
			{
				default:
					break;
				/* AutoTimer Editor */
				case 0:
				{
					AutoTimerViewController *avc = [[AutoTimerViewController alloc] init];
					[avc loadSettings]; // start loading settings to determine available features
					avc.timer = [AutoTimer timerFromEvent:event];
					if(!avc.timer.services.count)
						[avc.timer.services addObject:service];

					[multiEpgDelegate multiEPG:self pushViewController:avc animated:YES];
					// NOTE: set this here so the edit button won't get screwed
					avc.creatingNewTimer = YES;
					[_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
					break;
				}
				/* Timer Editor */
				case 1:
				{
					TimerViewController *targetViewController = [TimerViewController newWithEventAndService:event :service];
					[multiEpgDelegate multiEPG:self pushViewController:targetViewController animated:YES];
					[_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
					break;
				}
				/* Add Timer */
				case 2:
				{
					NSObject<TimerProtocol> *timer = [GenericTimer withEventAndService:event :service];

					Result *result = [[RemoteConnectorObject sharedRemoteConnector] addTimer:timer];
					if(result.result)
						showCompletedHudWithText(NSLocalizedString(@"Timer added", @"Text of HUD when timer was added successfully"))
						else
						{
							const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																				  message:[NSString stringWithFormat: NSLocalizedString(@"Error adding new timer: %@", @""), result.resulttext]
																				 delegate:nil
																		cancelButtonTitle:@"OK"
																		otherButtonTitles:nil];
							[alert show];
						}
					break;
				}
			}
		};

		// choice: autotimer editor, timer editor, add timer
		// this is different from the non-full or non-autotimer ui for consistency reasons
		// you get the convenience of just adding a timer without further interaction
		// but also the choice of opening the editor which is similar to the autotimer approach
		// because just adding an autotimer from the information we can gather here is stupid
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesAutoTimer] && [multiEpgDelegate respondsToSelector:@selector(multiEPG:pushViewController:animated:)])
		{
			if(IS_IPAD())
			{
				if(popoverController)
					[popoverController dismissPopoverAnimated:YES];
				SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:[NSArray arrayWithObjects:
																										  NSLocalizedStringFromTable(@"AutoTimer Editor", @"AutoTimer", @"Open Editor for new AutoTimer"),
																										  NSLocalizedString(@"Timer Editor", @"Open Editor for new Timer"),
																										  NSLocalizedString(@"Add Timer", @""),
																										  nil]
																							andSelection:NSNotFound
																								andTitle:nil];
				vc.callback = ^(NSUInteger selectedItem, BOOL isClosing, BOOL canceling){
					// NOTE: ignore cancel as the button is not visible in our case
					[popoverController dismissPopoverAnimated:YES];
					popoverController = nil;

					if(!isClosing)
						timer_function(selectedItem);

					return YES;
				};
				vc.contentSizeForViewInPopover = CGSizeMake(183.0f, 185.0f);
				popoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
				[popoverController presentPopoverFromRect:CGRectMake(p.x, p.y, 1, 1)
												   inView:_tableView
								 permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight
												 animated:YES];
			}
			else
			{
				UIActionSheet *as = [UIBlockActionSheet actionSheetWithTitle:nil
														   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
													  destructiveButtonTitle:nil
														   otherButtonTitles:[NSArray arrayWithObjects:NSLocalizedStringFromTable(@"AutoTimer Editor", @"AutoTimer", @"Open Editor for new AutoTimer"),
																			  NSLocalizedString(@"Timer Editor", @"Open Editor for new Timer"),
																			  NSLocalizedString(@"Add Timer", @""),
																			  nil]
																   onDismiss:^(UIActionSheet *actionSheet, NSInteger buttonIndex)
									 {
										 if(buttonIndex == actionSheet.cancelButtonIndex)
										 {
											// do nothing
										 }
										 else
										 {
											 timer_function(buttonIndex);
										 }
									 }];
				[as showFromTabBar:APP_DELEGATE.tabBarController.tabBar];
			}
		}
		else
			timer_function(2);
	}
	// no event selected: zap/stream
	else
	{
		// if streaming supported, show popover on ipad and action sheet on iphone
		if([ServiceZapListController canStream])
		{
			zap_callback_t callback = ^(ServiceZapListController *zlc, zapAction selectedAction)
			{
				NSURL *streamingURL = nil;
				NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
				if(self.zapListController == zlc)
					self.zapListController = nil;

				if(selectedAction == zapActionRemote)
				{
					[sharedRemoteConnector zapTo:service];
					return;
				}

				streamingURL = [sharedRemoteConnector getStreamURLForService:service];
				if(!streamingURL)
				{
					// Alert user
					const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																		  message:NSLocalizedString(@"Unable to generate stream URL.", @"Failed to retrieve or generate URL of remote stream")
																		 delegate:nil
																cancelButtonTitle:@"OK"
																otherButtonTitles:nil];
					[alert show];
				}
				else
                    [ServiceZapListController openStreamWithViewController:streamingURL withAction:selectedAction withViewController:self];
			};

			zapAction defaultZapAction = [[NSUserDefaults standardUserDefaults] integerForKey:kZapModeDefault];
			if(defaultZapAction != zapActionMax)
			{
				callback(nil, defaultZapAction);
			}
			else if(IS_IPAD())
			{
				// hide popover if already visible
				if([popoverController isPopoverVisible])
				{
					[popoverController dismissPopoverAnimated:YES];
					self.popoverController = nil;
					return;
				}

				ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
				zlc.callback = callback;
				popoverController = [[UIPopoverController alloc] initWithContentViewController:zlc];

				[popoverController presentPopoverFromRect:CGRectMake(p.x, p.y, 1, 1)
												   inView:_tableView
								 permittedArrowDirections:UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight
												 animated:YES];
			}
			else
			{
				zapListController = [ServiceZapListController showAlert:callback fromTabBar:self.tabBarController.tabBar];
			}
		}
		// else just zap on remote host
		else
		{
			[[RemoteConnectorObject sharedRemoteConnector] zapTo:service];
		}
	}
}

@end
