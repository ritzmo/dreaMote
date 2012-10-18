//
//  EventListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "EventListController.h"

#if IS_FULL()
	#import <ViewController/AutoTimerViewController.h>
	#import <ViewController/TimerViewController.h>
	#import <ListController/SimpleSingleSelectionListController.h>
	#import <Objects/Generic/AutoTimer.h>
#endif
#import <TableViewCell/EventTableViewCell.h>
#import <ViewController/EventViewController.h>
#import <ListController/ServiceZapListController.h>

#import "MBProgressHUD.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"

#import <Objects/EventProtocol.h>
#import <Objects/Generic/Result.h>
#import <Objects/Generic/Timer.h>
#import <Objects/ServiceProtocol.h>

#if IS_FULL()
	#import "EPGCache.h"
#endif

#import "SSKManager.h"

#define ONEDAY 86400

@interface EventListController()
/*!
 @brief initiate zap 
 @param sender ui element
 */
- (void)zapAction:(id)sender;

/*!
 @brief Event was/is being held.
 */
- (void)longPress:(UILongPressGestureRecognizer *)gesture;

/*!
 @brief Helper method for gesture handling.
 */
- (void)itemSelected:(NSNumber *)selection;

/*!
 @brief Zap type selection.
 */
@property (nonatomic, strong) ServiceZapListController *zapListController;

#if INCLUDE_FEATURE(Ads)
- (void)destroyAdBannerView;
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, strong) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
@end

@implementation EventListController

@synthesize dateFormatter, popoverController;
#if INCLUDE_FEATURE(Ads)
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;
#endif
@synthesize serviceListController;
@synthesize searchBar, isSlave, zapListController;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Events", @"Default Title of EventListController");
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_eventViewController = nil;
		_service = nil;
		_events = [NSMutableArray array];
		_gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		_sectionOffsets = [NSMutableArray array];
#if IS_FULL()
		_filteredEvents = [[NSMutableArray alloc] init];
#endif
	}
	return self;
}

/* new list for given service */
+ (EventListController*)forService: (NSObject<ServiceProtocol> *)ourService
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.service = ourService;

	return eventListController;
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
	_service = newService;

	// Set title
	self.title = newService.sname;

	// Clean event list
	_reloading = YES;
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
	// NOTE: offset is a little off on iPad iOS 4.2, but this is the best looking version on everything else
	[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
#endif

	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

/* dealloc */
- (void)dealloc
{
#if IS_FULL()
	_tableView.tableHeaderView = nil; // references searchBar
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
#endif
#if INCLUDE_FEATURE(Ads)
	[self destroyAdBannerView];
#endif
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	_eventViewController = nil;
	
    [super didReceiveMemoryWarning];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kEventCellHeight;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// Create zap button
	UIBarButtonItem *zapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zap", @"") style:UIBarButtonItemStylePlain target:self action:@selector(zapAction:)];
	self.navigationItem.rightBarButtonItem = zapButton;

#if IS_FULL()
	searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.keyboardType = UIKeyboardTypeDefault;
	_tableView.tableHeaderView = searchBar;

	// hide the searchbar
	[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height)];

	_searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	_searchDisplay.delegate = self;
	_searchDisplay.searchResultsDataSource = self;
	_searchDisplay.searchResultsDelegate = self;
#endif

	if(_reloading)
	{
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
		// NOTE: yes, this looks weird - but it works :P
		[_tableView setContentOffset:CGPointMake(0, -searchBar.frame.size.height/2.0f) animated:YES];
#endif
	}

#if INCLUDE_FEATURE(Ads)
	if(IS_IPHONE() && ![SSKManager isFeaturePurchased:kAdFreePurchase])
	{
		[self createAdBannerView];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adsWereRemoved:) name:kAdRemovalPurchased object:nil];
	}
#endif
	[self theme];
}

- (void)viewDidLoad
{
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[_tableView addGestureRecognizer:longPressGesture];

	[super viewDidLoad];
}

- (void)viewDidUnload
{
#if INCLUDE_FEATURE(Ads)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kAdRemovalPurchased object:nil];
	[self destroyAdBannerView];
#endif
#if IS_FULL()
	[_filteredEvents removeAllObjects];
	_tableView.tableHeaderView = nil; // references searchBar
	searchBar = nil;
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	_searchDisplay = nil;
#endif
	[super viewDidUnload];
}

/* start download of event list */
- (void)fetchData
{
#if IS_FULL()
	EPGCache *epgCache = [EPGCache sharedInstance];
	[epgCache stopTransaction];
	[epgCache startTransaction:_service];
#endif
	_reloading = YES;
	_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] fetchEPG:self service:_service];
}

/* remove content data */
- (void)emptyData
{
	const BOOL usedSections = _useSections;
#if INCLUDE_FEATURE(Extra_Animation)
	NSInteger sectionCount = _sectionOffsets.count;
#endif
	[_sectionOffsets removeAllObjects];
	_lastDay = NSNotFound;

	// Clean event list
	[_events removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	if(usedSections)
	{
		NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionCount)];
		[_tableView deleteSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	}
	else
		[_tableView reloadSections:[NSIndexSet indexSetWithIndex: 0] withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif

	// NOTE: change this here as previously we expect it to have the old value
	_useSections = [[NSUserDefaults standardUserDefaults] boolForKey:kSeparateEpgByDay];
	// fixup sections again
	if(!usedSections && _useSections)
	{
		[_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
	}
	else if(!_useSections && usedSections)
	{
		[_tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
	}

	_xmlReader = nil;
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/* about to rotate */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
#if INCLUDE_FEATURE(Ads)
	[self fixupAdView:toInterfaceOrientation];
#endif
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
#if INCLUDE_FEATURE(Ads)
	CGRect frame = _tableView.frame;
#ifndef __BOTTOM_AD__
	frame.origin.y += _adBannerHeight;
#endif
	frame.size.height -= _adBannerHeight;
	_tableView.frame = frame;

	[self fixupAdView:self.interfaceOrientation];
#endif
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
	[_tableView deselectRowAtIndexPath:tableSelection animated:YES];

#if INCLUDE_FEATURE(Ads)
	[self fixupAdView:self.interfaceOrientation];
#endif
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
#if IS_FULL()
	// end transaction here because there can only be a single active transaction at a time
	// if we didn't stop now the possibility of a corrupted cache is higher, though this way
	// we still could end up with a corrupted cache… the better way might be to add a
	// "transaction context" on the epgcache end and manage the cache from the event parsers
	// instead from the view.
	[[EPGCache sharedInstance] stopTransaction];
#endif

	[dateFormatter resetReferenceDate];

	// eventually remove popover
	if(popoverController)
	{
		[popoverController dismissPopoverAnimated:animated];
		self.popoverController = nil;
	}
	[super viewWillDisappear:animated];
}

- (void)sortEventsInSections:(BOOL)allowSearch
{
	[_sectionOffsets removeAllObjects];
	NSArray *events = _events;
#if IS_FULL()
	if(allowSearch && _searchDisplay.active) events = _filteredEvents;
#endif

	if(events.count && _useSections)
	{
		NSObject<EventProtocol> *firstEvent = [events objectAtIndex:0];
		NSDateComponents *components = [_gregorian components:NSDayCalendarUnit fromDate:firstEvent.begin];
		NSInteger lastDay = [components day];
		[_sectionOffsets addObject:[NSNumber numberWithInteger:0]];

		NSInteger idx = 1; // and after the first element
		for(NSObject<EventProtocol> *event in events)
		{
			if(event == firstEvent) continue;

			NSInteger thisDay = [[_gregorian components:NSDayCalendarUnit fromDate:event.begin] day];
			if(thisDay != lastDay)
			{
				lastDay = thisDay;
				[_sectionOffsets addObject:[NSNumber numberWithInteger:idx]];
			}
			++idx;
		}
	}

	[_tableView reloadData];
}

- (void)sortEventsInSections
{
	[self sortEventsInSections:YES];
}

#pragma mark Gestures

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
	// only do something on gesture start
	if(gesture.state != UIGestureRecognizerStateBegan)
		return;

	// get event
#if IS_FULL()
	UITableView *tableView = (_searchDisplay.active) ? _searchDisplay.searchResultsTableView : _tableView;
#else
	UITableView *tableView = _tableView;
#endif
	const CGPoint p = [gesture locationInView:tableView];
	NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
	NSObject<EventProtocol> *event = ((EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).event;

	// Check for invalid event
	if(!event || !event.valid)
		return;
	[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone]; // visiblity mark event

#if IS_FULL()
	// choice: autotimer editor, timer editor, add timer
	// this is different from the non-full or non-autotimer ui for consistency reasons
	// you get the convenience of just adding a timer without further interaction
	// but also the choice of opening the editor which is similar to the autotimer approach
	// because just adding an autotimer from the information we can gather here is stupid
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesAutoTimer])
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
					[self performSelectorOnMainThread:@selector(itemSelected:)
										   withObject:[NSNumber numberWithUnsignedInteger:selectedItem]
										waitUntilDone:NO];
				else
					[tableView deselectRowAtIndexPath:indexPath animated:YES];

				return YES;
			};
			vc.contentSizeForViewInPopover = CGSizeMake(183.0f, 185.0f);
			popoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
			CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
			cellRect.origin.x = p.x - 25.0f;
			cellRect.size.width = cellRect.size.width - cellRect.origin.x;
			[popoverController presentPopoverFromRect:cellRect
											   inView:tableView
							 permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight
											 animated:YES];
		}
		else
		{
			UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
											  destructiveButtonTitle:nil
												   otherButtonTitles:
								 NSLocalizedStringFromTable(@"AutoTimer Editor", @"AutoTimer", @"Open Editor for new AutoTimer"),
								 NSLocalizedString(@"Timer Editor", @"Open Editor for new Timer"),
								 NSLocalizedString(@"Add Timer", @""),
								 nil];
			if(self.tabBarController == nil) // XXX: bug in MGSplitViewController?
				[as showInView:self.view];
			else
				[as showFromTabBar:self.tabBarController.tabBar];
		}
	}
	else
#endif
		[self itemSelected:[NSNumber numberWithInteger:2]];
}

- (void)itemSelected:(NSNumber *)selection
{
#if IS_FULL()
	UITableView *tableView = (_searchDisplay.active) ? _searchDisplay.searchResultsTableView : _tableView;
#else
	UITableView *tableView = _tableView;
#endif
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
	NSObject<EventProtocol> *event = ((EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).event;

	NSObject<ServiceProtocol> *service = _service ? _service : event.service;
	if(!service)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															  message:NSLocalizedString(@"Unable to add timer: Service not found.", @"")
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		return;
	}

	switch([selection integerValue])
	{
		default:
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
#if IS_FULL()
		/* AutoTimer Editor */
		case 0:
		{
			AutoTimerViewController *avc = [[AutoTimerViewController alloc] init];
			[avc loadSettings]; // start loading settings to determine available features
			avc.timer = [AutoTimer timerFromEvent:event];
			if(!avc.timer.services.count)
				[avc.timer.services addObject:service];

			[self.navigationController pushViewController:avc animated:YES];
			// NOTE: set this here so the edit button won't get screwed
			avc.creatingNewTimer = YES;
			break;
		}
		/* Timer Editor */
		case 1:
		{
			TimerViewController *targetViewController = [TimerViewController newWithEventAndService:event :service];
			[self.navigationController pushViewController:targetViewController animated:YES];
			break;
		}
#endif
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
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
		}

	}
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
#if IS_FULL()
	UITableView *tableView = (_searchDisplay.active) ? _searchDisplay.searchResultsTableView : _tableView;
#else
	UITableView *tableView = _tableView;
#endif
	if(buttonIndex == actionSheet.cancelButtonIndex)
	{
		NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else
	{
		buttonIndex -= actionSheet.firstOtherButtonIndex;
		[self itemSelected:[NSNumber numberWithInteger:buttonIndex]];
	}
}

#pragma mark -
#pragma mark SwipeTableViewDelegate
#pragma mark -
#if IS_FULL()

- (void)tableView:(SwipeTableView *)tableView didSwipeRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(serviceListController == nil)
		return;
	if(![serviceListController respondsToSelector:@selector(nextService)] || ![serviceListController respondsToSelector:@selector(previousService)])
	{
#if IS_DEBUG()
		[NSException raise:@"ExcInvalidServiceList" format:@"serviceListController assigned but not responding to next-/previousService selectors"];
#endif
		return;
	}

	//if(tableView.lastSwipe & twoFingers)
	{
		// fixup selection
		NSIndexPath *idxPath = [_tableView indexPathForSelectedRow];
		if(idxPath)
			[_tableView deselectRowAtIndexPath:idxPath animated:YES];

		NSObject<ServiceProtocol> *newService = nil;
		if(tableView.lastSwipe & swipeTypeRight)
			newService = [serviceListController previousService];
		else // if(tableView.lastSwipe & swipeTypeLeft)
			newService = [serviceListController nextService];

		if(newService)
			self.service = newService;
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"End of service list reached", @"Title of message when trying to select next/previous service by swiping but end was reached.")
																  message:NSLocalizedString(@"You have reached either the end or the beginning of the selected service list.", @"")
																 delegate:nil
														cancelButtonTitle:@"OK"
														otherButtonTitles:nil];
			[alert show];
		}
	}
}

#endif

#pragma mark -
#pragma mark DataSourceDelegate methods
#pragma mark -

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	[super dataSourceDelegate:dataSource errorParsingDocument:error];
#if IS_FULL()
	[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height) animated:YES];
#endif
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = (_useSections) ? [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _sectionOffsets.count)] : [NSIndexSet indexSetWithIndex: 0];;
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
#endif
#if IS_FULL()
	[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height) animated:YES];
#endif
}

#pragma mark -
#pragma mark EventSourceDelegate methods
#pragma mark -

/* add event to list */
- (void)addEvent: (NSObject<EventProtocol> *)event
{
#if INCLUDE_FEATURE(Extra_Animation)
	BOOL skipAnimation = NO;
#endif
	[_events addObject: event];
	NSInteger idx = _events.count-1;
	if(_useSections)
	{
		if(idx == 0)
		{
			NSDateComponents *components = [_gregorian components:NSDayCalendarUnit fromDate:event.begin];
			_lastDay = [components day];
			[_sectionOffsets addObject:[NSNumber numberWithInteger:0]];
#if INCLUDE_FEATURE(Extra_Animation)
			[_tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
			skipAnimation = YES;
#endif
		}
		else
		{
			NSInteger thisDay = [[_gregorian components:NSDayCalendarUnit fromDate:event.begin] day];
			if(thisDay != _lastDay)
			{
				_lastDay = thisDay;
				[_sectionOffsets addObject:[NSNumber numberWithInteger:idx]];
#if INCLUDE_FEATURE(Extra_Animation)
				[_tableView insertSections:[NSIndexSet indexSetWithIndex:_sectionOffsets.count-1] withRowAnimation:UITableViewRowAnimationLeft];
				skipAnimation = YES;
#endif
			}
		}
#if INCLUDE_FEATURE(Extra_Animation)
		idx -= [[_sectionOffsets lastObject] integerValue];
#endif
	}

#if INCLUDE_FEATURE(Extra_Animation)
	if(!skipAnimation)
		[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:(_useSections) ? _sectionOffsets.count - 1 : 0]]
						  withRowAnimation:UITableViewRowAnimationLeft];
#endif

#if IS_FULL()
	[[EPGCache sharedInstance] addEventOperation:event];
#endif
}

/* add events to list */
- (void)addEvents:(NSArray *)items
{
	NSUInteger count = _events.count;
#if INCLUDE_FEATURE(Extra_Animation)
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:items.count];
	[_tableView beginUpdates];
#endif
	[_events addObjectsFromArray:items];
#if IS_FULL()
	EPGCache *epgCache = [EPGCache sharedInstance];
#endif
	for(NSObject<EventProtocol> *event in items)
	{
#if IS_FULL()
		[epgCache addEventOperation:event];
#endif
		if(_useSections)
		{
			if(count == 0)
			{
				NSDateComponents *components = [_gregorian components:NSDayCalendarUnit fromDate:event.begin];
				_lastDay = [components day];
				[_sectionOffsets addObject:[NSNumber numberWithInteger:0]];
#if INCLUDE_FEATURE(Extra_Animation)
				[_tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
				++count;
				continue;
#endif
			}
			else
			{
				NSInteger thisDay = [[_gregorian components:NSDayCalendarUnit fromDate:event.begin] day];
				if(thisDay != _lastDay)
				{
					_lastDay = thisDay;
					[_sectionOffsets addObject:[NSNumber numberWithInteger:count]];
#if INCLUDE_FEATURE(Extra_Animation)
					[_tableView insertSections:[NSIndexSet indexSetWithIndex:_sectionOffsets.count-1] withRowAnimation:UITableViewRowAnimationLeft];
					++count;
					continue;
#endif
				}
			}
#if INCLUDE_FEATURE(Extra_Animation)
			[indexPaths addObject:[NSIndexPath indexPathForRow:count - [[_sectionOffsets lastObject] integerValue] inSection:_sectionOffsets.count - 1]];
#endif
		}
#if INCLUDE_FEATURE(Extra_Animation)
		else
		{
			[indexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];
		}
#endif
		++count;
	}
#if INCLUDE_FEATURE(Extra_Animation)
	if(indexPaths)
		[_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
	[_tableView endUpdates];
#endif
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *events = _events;
#if IS_FULL()
	if(tableView == _searchDisplay.searchResultsTableView) events = _filteredEvents;
#endif
	EventTableViewCell *cell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];

	cell.formatter = dateFormatter;
	@try
	{
		if(_useSections)
		{
			const NSInteger offset = [[_sectionOffsets objectAtIndex:indexPath.section] integerValue];
			cell.event = (NSObject<EventProtocol> *)[events objectAtIndex:offset + indexPath.row];
		}
		else
			cell.event = (NSObject<EventProtocol> *)[events objectAtIndex: indexPath.row];
	}
	@catch (NSException *exception)
	{
		cell.event = nil;
		NSLog(@"[EventListController] Exception while trying to assign event to cell (%d, %d - max %d): %@", indexPath.section, indexPath.row, [events count], [exception description]);
#if IS_DEBUG()
		[exception raise];
#endif
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave];
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<EventProtocol> *event = ((EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).event;

	if(!event.valid)
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];

	if(_eventViewController == nil)
		_eventViewController = [[EventViewController alloc] init];

	_eventViewController.event = event;
	_eventViewController.service = _service;

	// XXX: wtf?
	if([self.navigationController.viewControllers containsObject:_eventViewController])
	{
#if IS_DEBUG()
		NSMutableString* result = [[NSMutableString alloc] init];
		for(NSObject* obj in self.navigationController.viewControllers)
			[result appendString:[obj description]];
		[NSException raise:@"EventViewTwiceInNavigationStack" format:@"_eventViewController was twice in navigation stack: %@", result];
#endif
		[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
	}
	[self.navigationController pushViewController:_eventViewController animated: YES];
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return _useSections ? _sectionOffsets.count : 1;
}

/* header height */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(_useSections)
		return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
	return 0.0001;
}

/* section header */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
}

/* section titles */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_useSections)
	{
		NSArray *events = _events;
#if IS_FULL()
		if(tableView == _searchDisplay.searchResultsTableView) events = _filteredEvents;
#endif
		NSDateFormatter *format = [[NSDateFormatter alloc] init];
		format.dateStyle = NSDateFormatterMediumStyle;
		format.timeStyle = NSDateFormatterNoStyle;

		if(section >= (NSInteger)_sectionOffsets.count)
		{
#if IS_DEBUG()
			[NSException raise:@"ExcEventListInvalidSection" format:@"Title for invalid section (%d of %d) was requested.", section, _sectionOffsets.count];
#endif
			return @"???";
		}

		NSUInteger offset = [[_sectionOffsets objectAtIndex:section] integerValue];
		if(offset >= events.count)
		{
#if IS_DEBUG()
			[NSException raise:@"ExcEventListInvalidEvent" format:@"Tried to generate section title from invalid event (%d of %d).", offset, events.count];
#endif
			return @"???";
		}

		NSObject<EventProtocol> *event = (NSObject<EventProtocol> *)[events objectAtIndex:offset];
		NSString *title = [format fuzzyDate:event.begin];
		return title;
	}
	return nil;
}

/* number of items */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSArray *events = _events;
#if IS_FULL()
	if(tableView == _searchDisplay.searchResultsTableView) events = _filteredEvents;
#endif
	if(_useSections)
	{
		if((NSUInteger)section == _sectionOffsets.count - 1)
			return events.count - [[_sectionOffsets lastObject] integerValue];
		else if(_sectionOffsets.count != 0)
			return [[_sectionOffsets objectAtIndex:section + 1] integerValue] - [[_sectionOffsets objectAtIndex:section] integerValue];
#if IS_DEBUG()
		[NSException raise:@"ExcInvalidSectionOffset" format:@"Invalid section or no offset set (section %d of %d", section, _sectionOffsets.count - 1];
#endif
		return 0;
	}
	return [events count];
}

#pragma mark ADBannerViewDelegate
#if INCLUDE_FEATURE(Ads)

//#define __BOTTOM_AD__

- (CGFloat)getBannerHeight:(UIInterfaceOrientation)orientation
{
	if(UIInterfaceOrientationIsLandscape(orientation))
		return IS_IPAD() ? 66 : 32;
	else
		return IS_IPAD() ? 66 : 50;
}

- (CGFloat)getBannerHeight
{
	return [self getBannerHeight:self.interfaceOrientation];
}

- (void)createAdBannerView
{
	self.adBannerView = [[ADBannerView alloc] initWithFrame:CGRectZero];
	[_adBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects:
													  ADBannerContentSizeIdentifierPortrait,
													  ADBannerContentSizeIdentifierLandscape,
													  nil]];
	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
	}
	else
	{
		[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
	}
#ifdef __BOTTOM_AD__
	// Banner at Bottom
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	CGSize cgSize = cgRect.size;
	[_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, cgSize.height + [self getBannerHeight])];
#else
	// Banner at the Top
	[_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, -[self getBannerHeight])];
#endif
	[_adBannerView setDelegate:self];

	[self.view addSubview:_adBannerView];
}

- (void)destroyAdBannerView
{
	//[_adBannerView cancelBannerViewAction];
	[_adBannerView removeFromSuperview];
	_adBannerView.delegate = nil;
	_adBannerView = nil;
}

- (void)adsWereRemoved:(NSNotification *)note
{
	_adBannerViewIsVisible = NO;
	[self fixupAdView:self.interfaceOrientation];
	[self destroyAdBannerView];
}

- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (_adBannerView != nil)
	{
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
		{
			[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
		}
		else
		{
			[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
		}
		[UIView beginAnimations:@"fixupViews" context:nil];
		if(_adBannerViewIsVisible)
		{
			CGRect adBannerViewFrame = [_adBannerView frame];
			CGRect contentViewFrame = _tableView.frame;
			CGFloat newBannerHeight = [self getBannerHeight:toInterfaceOrientation];

#ifndef __BOTTOM_AD__
			contentViewFrame.origin.y -= _adBannerHeight;
#endif
			contentViewFrame.size.height += _adBannerHeight;
			_adBannerHeight = newBannerHeight;

			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			adBannerViewFrame.origin.y = self.view.frame.size.height - newBannerHeight;
#else
			adBannerViewFrame.origin.y = contentViewFrame.origin.y;
#endif
			[_adBannerView setFrame:adBannerViewFrame];
			[self.view bringSubviewToFront:_adBannerView];

#ifdef __BOTTOM_AD__
			contentViewFrame.origin.y = 0;
#else
			contentViewFrame.origin.y += newBannerHeight;
#endif
			contentViewFrame.size.height -= newBannerHeight;
			_tableView.frame = contentViewFrame;
		}
		else
		{
			CGRect adBannerViewFrame = [_adBannerView frame];
			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			adBannerViewFrame.origin.y = self.view.frame.size.height + [self getBannerHeight:toInterfaceOrientation];
#else
			adBannerViewFrame.origin.y = -[self getBannerHeight:toInterfaceOrientation];
#endif
			[_adBannerView setFrame:adBannerViewFrame];

			CGRect contentViewFrame = _tableView.frame;
#ifndef __BOTTOM_AD__
			contentViewFrame.origin.y -= _adBannerHeight;
#endif
			contentViewFrame.size.height += _adBannerHeight;
			_tableView.frame = contentViewFrame;
			_adBannerHeight = 0;
		}
		[UIView commitAnimations];
	}
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	if(!_adBannerViewIsVisible)
	{
		_adBannerViewIsVisible = YES;
		[self fixupAdView:self.interfaceOrientation];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	if(_adBannerViewIsVisible)
	{
		_adBannerViewIsVisible = NO;
		[self fixupAdView:self.interfaceOrientation];
	}
}
#endif

#pragma mark Zapping

/* zap */
- (void)zapAction:(id)sender
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
				[sharedRemoteConnector zapTo:_service];
				return;
			}

			streamingURL = [sharedRemoteConnector getStreamURLForService:_service];
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

			[popoverController presentPopoverFromBarButtonItem:sender
									  permittedArrowDirections:UIPopoverArrowDirectionUp
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
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
	}
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -
#if IS_FULL()

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if(scrollView != _searchDisplay.searchResultsTableView)
		[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(scrollView != _searchDisplay.searchResultsTableView)
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#endif

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
#pragma mark -
#if IS_FULL()

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[_filteredEvents removeAllObjects];
	const BOOL caseInsensitive = [searchString isEqualToString:[searchString lowercaseString]];
	NSStringCompareOptions options = caseInsensitive ? (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) : 0;
	for(NSObject<EventProtocol> *event in _events)
	{
		NSRange range = [event.title rangeOfString:searchString options:options];
		if(range.length)
			[_filteredEvents addObject:event];
	}
	[self sortEventsInSections];

	return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
	// refresh the list
	[self sortEventsInSections:NO];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)searchTableView
{
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[searchTableView addGestureRecognizer:longPressGesture];
	searchTableView.rowHeight = _tableView.rowHeight;
	[searchTableView reloadData];
}

#endif
#pragma mark -
#pragma mark UIPopoverControllerDelegate methods
#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)pc
{
	// cleanup memory
	if([pc isEqual:self.popoverController])
		self.popoverController = nil;
}

@end
