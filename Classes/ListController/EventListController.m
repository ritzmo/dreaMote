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
#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"

#import "Objects/ServiceProtocol.h"
#import "Objects/EventProtocol.h"

#if IS_FULL()
	#import "EPGCache.h"
#endif

#define ONEDAY 86400

@interface EventListController()
/*!
 @brief initiate zap 
 @param sender ui element
 */
- (void)zapAction:(id)sender;
#if INCLUDE_FEATURE(Ads)
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, retain) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
@end

@implementation EventListController

@synthesize dateFormatter = _dateFormatter;
@synthesize popoverController;
#if INCLUDE_FEATURE(Ads)
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;
#endif

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Events", @"Default Title of EventListController");
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_eventViewController = nil;
		_service = nil;
		_events = [[NSMutableArray array] retain];
		_sectionOffsets = [[NSMutableArray array] retain];
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
	SafeRetainAssign(_service, newService);

	// Set title
	self.title = newService.sname;

	// Clean event list
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];

	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

/* dealloc */
- (void)dealloc
{
	[_events release];
	[_service release];
	[_dateFormatter release];
	[_eventViewController release];
	[_eventXMLDoc release];
	[popoverController release];
	[_zapListController release];
	[_sectionOffsets release];
#if INCLUDE_FEATURE(Ads)
	[_adBannerView setDelegate:nil];
	[_adBannerView release];
	_adBannerView = nil;
#endif

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
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kEventCellHeight;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// Create zap button
	UIBarButtonItem *zapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zap", @"") style:UIBarButtonItemStylePlain target:self action:@selector(zapAction:)];
	self.navigationItem.rightBarButtonItem = zapButton;
	[zapButton release];
	
#if INCLUDE_FEATURE(Ads)
	if(IS_IPHONE())
		[self createAdBannerView];
#endif
}

- (void)viewDidUnload
{
#if INCLUDE_FEATURE(Ads)
	[_adBannerView setDelegate:nil];
	[_adBannerView release];
	_adBannerView = nil;
#endif
	[super viewDidUnload];
}

/* start download of event list */
- (void)fetchData
{
#if IS_FULL()
	[[EPGCache sharedInstance] startTransaction:_service];
#endif
	_reloading = YES;
	SafeRetainAssign(_eventXMLDoc, [[RemoteConnectorObject sharedRemoteConnector] fetchEPG:self service:_service]);
}

/* remove content data */
- (void)emptyData
{
	const BOOL usedSections = _useSections;
	NSInteger sectionCount = _sectionOffsets.count;
	[_sectionOffsets removeAllObjects];
	_firstDay = 0;

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

	SafeRetainAssign(_eventXMLDoc, nil);
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

	[_dateFormatter resetReferenceDate];

	// eventually remove popover
	if(popoverController)
	{
		[popoverController dismissPopoverAnimated:animated];
		self.popoverController = nil;
	}
	[super viewWillDisappear:animated];
}

- (void)sortEventsInSections
{
	[_sectionOffsets removeAllObjects];

	if(_events.count)
	{
		NSObject<EventProtocol> *firstEvent = [_events objectAtIndex:0];
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:firstEvent.begin];
		[components setHour:0];
		NSDate *date = [gregorian dateFromComponents:components];
		_firstDay = [date timeIntervalSince1970];
		[_sectionOffsets addObject:[NSNumber numberWithInteger:0]];

		[gregorian release];

		NSInteger numSections = 1; // we start with one section
		NSInteger idx = 1; // and after the first element
		for(NSObject<EventProtocol> *event in _events)
		{
			if(event == firstEvent) continue;

			NSTimeInterval secSinceFirst = [event.begin timeIntervalSince1970] - _firstDay;
			while(secSinceFirst > numSections * ONEDAY) // NOTE: a while is probably not necessary, but we better make sure
			{
				[_sectionOffsets addObject:[NSNumber numberWithInteger:idx]];
				++numSections;
			}
			++idx;
		}
	}

	[_tableView reloadData];
}

#pragma mark -
#pragma mark DataSourceDelegate methods
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = (_useSections) ? [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _sectionOffsets.count)] : [NSIndexSet indexSetWithIndex: 0];;
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
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
			NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
			NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:event.begin];
			[components setHour:0];
			NSDate *date = [gregorian dateFromComponents:components];
			_firstDay = [date timeIntervalSince1970];
			[_sectionOffsets addObject:[NSNumber numberWithInteger:0]];

			[gregorian release];
#if INCLUDE_FEATURE(Extra_Animation)
			[_tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
			skipAnimation = YES;
#endif
		}
		else
		{
			NSTimeInterval secSinceFirst = [event.begin timeIntervalSince1970] - _firstDay;
			NSInteger numSections = _sectionOffsets.count;
			while(secSinceFirst > numSections * ONEDAY) // NOTE: a while is probably not necessary, but we better make sure
			{
				[_sectionOffsets addObject:[NSNumber numberWithInteger:idx]];
#if INCLUDE_FEATURE(Extra_Animation)
				[_tableView insertSections:[NSIndexSet indexSetWithIndex:numSections] withRowAnimation:UITableViewRowAnimationLeft];
				skipAnimation = YES;
#endif
				++numSections;
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
	[NSThread detachNewThreadSelector:@selector(addEventThreaded:) toTarget:[EPGCache sharedInstance] withObject:event];
#endif
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	EventTableViewCell *cell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];

	cell.formatter = _dateFormatter;
	cell.showService = NO;
	if(_useSections)
	{
		const NSInteger offset = [[_sectionOffsets objectAtIndex:indexPath.section] integerValue];
		cell.event = (NSObject<EventProtocol> *)[_events objectAtIndex:offset + indexPath.row];
	}
	else
		cell.event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		[NSException raise:@"EventListUserInteractionWhileReloading" format:@"willSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return nil;
	}

	NSObject<EventProtocol> *event = ((EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).event;

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
		[result release]; // never reached, but to keep me from going crazy :)
#endif
		[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
	}
	[self.navigationController pushViewController: _eventViewController animated: YES];

	return indexPath;
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return _useSections ? _sectionOffsets.count : 1;
}

/* section header height */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
#ifndef defaultSectionHeaderHeight
	#define defaultSectionHeaderHeight 34
#endif
	return _useSections ? defaultSectionHeaderHeight: 0;
}

/* section titles */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_useSections)
	{
		NSDateFormatter *format = [[NSDateFormatter alloc] init];
		format.dateStyle = NSDateFormatterShortStyle;
		format.timeStyle = NSDateFormatterNoStyle;
		NSObject<EventProtocol> *event = (NSObject<EventProtocol> *)[_events objectAtIndex:[[_sectionOffsets objectAtIndex:section] integerValue]];
		NSString *title = [format fuzzyDate:event.begin];
		[format release];
		return title;
	}
	return nil;
}

/* number of items */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(_useSections)
	{
		if((NSUInteger)section == _sectionOffsets.count - 1)
			return _events.count - [[_sectionOffsets lastObject] integerValue];
		else if(_sectionOffsets.count != 0)
			return [[_sectionOffsets objectAtIndex:section + 1] integerValue] - [[_sectionOffsets objectAtIndex:section] integerValue];
#if IS_DEBUG()
		[NSException raise:@"ExcInvalidSectionOffset" format:@"Invalid section or no offset set (section %d of %d", section, _sectionOffsets.count - 1];
#endif
		return 0;
	}
	return [_events count];
}

#pragma mark ADBannerViewDelegate
#if INCLUDE_FEATURE(Ads)

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
		if(IS_IPAD())
		{
			// hide popover if already visible
			if([popoverController isPopoverVisible])
			{
				[popoverController dismissPopoverAnimated:YES];
				self.popoverController = nil;
				return;
			}

			ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
			zlc.zapDelegate = self;
			[popoverController release];
			popoverController = [[UIPopoverController alloc] initWithContentViewController:zlc];
			[zlc release];

			[popoverController presentPopoverFromBarButtonItem:sender
									  permittedArrowDirections:UIPopoverArrowDirectionUp
													  animated:YES];
		}
		else
		{
			SafeRetainAssign(_zapListController, [ServiceZapListController showAlert:self fromTabBar:self.tabBarController.tabBar]);
		}
	}
	// else just zap on remote host
	else
	{
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
	}
}

#pragma mark -
#pragma mark ServiceZapListDelegate methods
#pragma mark -

- (void)serviceZapListController:(ServiceZapListController *)zapListController selectedAction:(zapAction)selectedAction
{
	NSURL *streamingURL = nil;
	NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
	SafeRetainAssign(_zapListController, nil);

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
		[alert release];
	}
	else
		[ServiceZapListController openStream:streamingURL withAction:selectedAction];
}

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
