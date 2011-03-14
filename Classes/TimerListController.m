//
//  TimerListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "TimerListController.h"

#import "TimerViewController.h"

#import "NSDateFormatter+FuzzyFormatting.h"
#import "UIDevice+SystemVersion.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "TimerTableViewCell.h"

#import "Objects/Generic/Timer.h"
#import "Objects/Generic/Result.h"

@interface TimerListController()
#if IS_LITE()
- (void)createAdBannerView;
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, retain) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
- (void)cleanupTimers:(id)sender;
@end


@implementation TimerListController

@synthesize timers = _timers;
@synthesize dateFormatter = _dateFormatter;
@synthesize isSplit = _isSplit;
@synthesize timerViewController = _timerViewController;
@synthesize willReappear = _willReappear;
#if IS_LITE()
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;
#endif

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.timers = [NSMutableArray array];
		self.title = NSLocalizedString(@"Timers", @"Title of TimerListController");
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_timerViewController = nil;
		_willReappear = NO;
		_isSplit = NO;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_cleanupButton release];
	[_dateFormatter release];
	[_timers release];
	[_timerViewController release];
#if IS_LITE()
	[_adBannerView release];
#endif

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	if(!IS_IPAD())
	{
		[_timerViewController release];
		_timerViewController = nil;
	}
	
    [super didReceiveMemoryWarning];
}

- (void)cleanupTimers:(id)sender
{
	// TODO: generate list of timers to clean up if non-native, but for now we don't support that anyway
	Result *result = [[RemoteConnectorObject sharedRemoteConnector] cleanupTimers:nil];
	if(!result.result)
	{
		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error cleaning up", @"Title of alert when timer cleanup failed")
															  message:result.resulttext
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		[alert release];
	}

	// reload data
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];

	// Spawn a thread to fetch the timer data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 62;

	_cleanupButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cleanup", @"Timer cleanup button") style:UIBarButtonItemStylePlain target:self action:@selector(cleanupTimers:)];

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
#if IS_LITE()
	if(IS_IPHONE())
		[self createAdBannerView];
#endif
}

- (void)setWillReappear:(BOOL)new
{
	// allow to skip refresh only if there is any data
	/*
	 @note this prevents problems with iOS3.2 where sections were not properly reloaded
	 resulting in double section headers with the first set hiding the first timer.
	 */
	if(_dist[0] > 0) _willReappear = new;
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[_tableView setEditing: editing animated: animated];

	if(animated)
	{
		if(editing)
		{
			[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationTop];
		}
		else
		{
			[_tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationTop];
		}
	}
	else
		[_tableView reloadData];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesTimerCleanup])
		self.navigationItem.leftBarButtonItem = _cleanupButton;
	else
		self.navigationItem.leftBarButtonItem = nil;

	if(!_willReappear && !_reloading)
	{
		[self emptyData];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];

		// Spawn a thread to fetch the timer data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
		[_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
	}

	_willReappear = NO;

	[super viewWillAppear: animated];
#if IS_LITE()
	[self fixupAdView:self.interfaceOrientation];
#endif
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this won't reset the editButtonItem
	if(self.editing)
		[self setEditing:NO animated: YES];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	// Clear remaining caches if not reappearing
	if(!_willReappear)
	{
		if(!IS_IPAD())
		{
			[_timerViewController release];
			_timerViewController = nil;

			[self emptyData];
		}
	}

	// Reset reference date of date formatter
	[_dateFormatter resetReferenceDate];
}

/* fetch timer list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_timerXMLDoc release];
	_reloading = YES;
	_timerXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchTimers: self] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	NSUInteger i = 0;

	// Clean timer list
	for(i = 0; i < kTimerStateMax; i++)
		_dist[i] = 0;
	[_timers removeAllObjects];

	/*!
	 @note at least 3.2 has problems with repositioning the section titles, so only do a
	 "pretty" reload on 4.0+
	 */
	if([UIDevice runsIos4OrBetter])
	{
		NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, kTimerStateMax + 1)];
		[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	}
	else
	{
		[_tableView reloadData];
	}

	[_timerXMLDoc release];
	_timerXMLDoc = nil;
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
#if IS_LITE()
	[self fixupAdView:toInterfaceOrientation];
#endif
}

#pragma mark -
#pragma mark -
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadData];
}

#pragma mark -
#pragma mark TimerSourceDelegate
#pragma mark -

/* add timer to list */
- (void)addTimer: (NSObject<TimerProtocol> *)newTimer
{
	NSUInteger state = newTimer.state;
	NSUInteger index = _dist[state];

	[_timers insertObject: newTimer atIndex: index];

	for(; state < kTimerStateMax; state++){
		_dist[state]++;
	}
#ifdef ENABLE_LAGGY_ANIMATIONS
	state = newTimer.state;
	if(state > 0)
		index -= _dist[state - 1];

	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: index inSection: state + 1]]
					  withRowAnimation: UITableViewRowAnimationTop];
#endif
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *cell = nil;

	// First section, "New Timer"
	if(section == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
		if(cell == nil)
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"New Timer", @"");
		TABLEVIEWCELL_FONT(cell) = [UIFont systemFontOfSize:kTextViewFontSize]; // FIXME: Looks a little weird though

		return cell;
	}

	// Timer state is section - 1, so make this a little more readable
	--section;

	// Acquire cell
	cell = [tableView dequeueReusableCellWithIdentifier:kTimerCell_ID];
	if(cell == nil)
		cell = [[[TimerTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kTimerCell_ID] autorelease];

	// Assign item
	NSInteger offset = 0;
	if(section > 0)
		offset = _dist[section-1];
	((TimerTableViewCell *)cell).formatter = _dateFormatter;
	((TimerTableViewCell *)cell).timer = [_timers objectAtIndex: offset + indexPath.row];

	return cell;
}

/* row selected */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = indexPath.row;
	const NSInteger section = indexPath.section - 1;
	if(section > 0)
		index += _dist[section - 1];

	NSObject<TimerProtocol> *timer = [_timers objectAtIndex: index];
	if(!timer.valid)
	{
		[tableView deselectRowAtIndexPath: indexPath animated: YES];
		return nil;
	}

	NSObject<TimerProtocol> *ourCopy = [timer copy];

	if(_timerViewController == nil)
		_timerViewController = [[TimerViewController alloc] init];

	if(!IS_IPAD())
		_willReappear = YES;

	_timerViewController.delegate = self;
	_timerViewController.timer = timer;
	_timerViewController.oldTimer = ourCopy;
	[ourCopy release];

	// when in split view go back to timer view, else push it on the stack
	if(!_isSplit)
		[self.navigationController pushViewController: _timerViewController animated:YES];
	else
		[_timerViewController.navigationController popToRootViewControllerAnimated: YES];

	// NOTE: set this here so the edit button won't get screwed
	_timerViewController.creatingNewTimer = NO;
	return indexPath;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return kTimerStateMax + 1;
}

/* section title */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return nil;
	--section;

	if(section == kTimerStateWaiting)
		return NSLocalizedString(@"Waiting", @"Timer type");
	else if(section == kTimerStatePrepared)
		return NSLocalizedString(@"Prepared", @"Timer type");
	else if (section == kTimerStateRunning)
		return NSLocalizedString(@"Running", @"Timer type");
	else
		return NSLocalizedString(@"Finished", @"Timer type");
}

/* rows in section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	// First section only has an item when editing
	if(section == 0)
	{
		return (self.editing) ? 1 : 0;
	}
	--section;

	if(section > 0)
		return _dist[section] - _dist[section-1];
	return _dist[0];
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSUInteger index = indexPath.row;
		NSUInteger section = indexPath.section - 1;
		if(section > 0)
			index += _dist[section - 1];

		NSObject<TimerProtocol> *timer = [_timers objectAtIndex: index];
		if(!timer.valid)
			return;

		// Try to delete timer
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] delTimer: timer];
		if(result.result)
		{
			// If we have a constant timer Id don't refresh all data
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesConstantTimerId])
			{
				for(; section < kTimerStateMax; section++){
					_dist[section]--;
				}

				[_timers removeObjectAtIndex: index];

				[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
								 withRowAnimation: UITableViewRowAnimationFade];
			}
			// Else reload data
			else
			{
				// NOTE: this WILL reset our scroll position..
				[self emptyData];

				// Spawn a thread to fetch the timer data so that the UI is not blocked while the
				// application parses the XML file.
				[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
			}
		}
		// Timer could not be deleted
		else
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:result.resulttext
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
	// Add new Timer
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		if(_timerViewController == nil)
			_timerViewController = [[TimerViewController alloc] init];

		if(!IS_IPAD())
			_willReappear = YES;

		NSObject<TimerProtocol> *newTimer = [GenericTimer timer];
		_timerViewController.delegate = self;
		_timerViewController.timer = newTimer;
		_timerViewController.oldTimer = nil;

		// when in split view go back to timer view, else push it on the stack
		if(!_isSplit)
			[self.navigationController pushViewController: _timerViewController animated:YES];
		else
		{
			[_timerViewController.navigationController popToRootViewControllerAnimated: YES];
			[self setEditing:NO animated:YES];
		}

		// NOTE: set this here so the edit button won't get screwed
		_timerViewController.creatingNewTimer = YES;
	}
}

#pragma mark -
#pragma mark TimerViewControllerDelegate
#pragma mark -

- (void)timerViewController:(TimerViewController *)tvc timerWasAdded:(NSObject<TimerProtocol> *)timer
{
	// TODO: check if we can implement optimized reload
	[self emptyData];
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

- (void)timerViewController:(TimerViewController *)tvc timerWasEdited:(NSObject<TimerProtocol> *)timer :(NSObject<TimerProtocol> *)oldTimer;
{
	// TODO: check if we can implement optimized reload
	[self emptyData];
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

- (void)timerViewController:(TimerViewController *)tvc editingWasCanceled:(NSObject<TimerProtocol> *)timer;
{
	// do we need this for anything?
}

#pragma mark ADBannerViewDelegate
#if IS_LITE()

//#define __BOTTOM_AD__

- (CGFloat)getBannerHeight:(UIDeviceOrientation)orientation
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
	Class classAdBannerView = NSClassFromString(@"ADBannerView");
	if(classAdBannerView != nil)
	{
		self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectZero] autorelease];
		[_adBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects:
														  bannerContentSizeIdentifierPortrait,
														  bannerContentSizeIdentifierLandscape,
														  nil]];
		if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		{
			[_adBannerView setCurrentContentSizeIdentifier:bannerContentSizeIdentifierLandscape];
		}
		else
		{
			[_adBannerView setCurrentContentSizeIdentifier:bannerContentSizeIdentifierPortrait];
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
}

- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (_adBannerView != nil)
	{
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
		{
			[_adBannerView setCurrentContentSizeIdentifier:bannerContentSizeIdentifierLandscape];
		}
		else
		{
			[_adBannerView setCurrentContentSizeIdentifier:bannerContentSizeIdentifierPortrait];
		}
		[UIView beginAnimations:@"fixupViews" context:nil];
		if(_adBannerViewIsVisible)
		{
			CGRect adBannerViewFrame = [_adBannerView frame];
			CGRect contentViewFrame = _tableView.frame;
			CGFloat newBannerHeight = [self getBannerHeight:toInterfaceOrientation];
			
			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			adBannerViewFrame.origin.y = self.view.frame.size.height - newBannerHeight;
#else
			adBannerViewFrame.origin.y = 0;
#endif
			[_adBannerView setFrame:adBannerViewFrame];
			[self.view bringSubviewToFront:_adBannerView];

#ifdef __BOTTOM_AD__
			contentViewFrame.origin.y = 0;
#else
			contentViewFrame.origin.y = newBannerHeight;
#endif
			contentViewFrame.size.height = self.view.frame.size.height - newBannerHeight;
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
			contentViewFrame.origin.y = 0;
			contentViewFrame.size.height = self.view.frame.size.height;
			_tableView.frame = contentViewFrame;
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

@end
