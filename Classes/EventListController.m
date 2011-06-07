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
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
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
#if INCLUDE_FEATURE(Ads)
	[_adBannerView release];
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
	_tableView.sectionHeaderHeight = 0;

	// Create zap button
	UIBarButtonItem *zapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zap", @"") style:UIBarButtonItemStylePlain target:self action:@selector(zapAction:)];
	self.navigationItem.rightBarButtonItem = zapButton;
	[zapButton release];
	
#if INCLUDE_FEATURE(Ads)
	if(IS_IPHONE())
		[self createAdBannerView];
#endif
}


/* start download of event list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_eventXMLDoc release];
#if IS_FULL()
	[[EPGCache sharedInstance] startTransaction:_service];
#endif
	_reloading = YES;
	_eventXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchEPG: self service: _service] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_events removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	[_eventXMLDoc release];
	_eventXMLDoc = nil;
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

#pragma mark -
#pragma mark EventSourceDelegate methods
#pragma mark -

/* add event to list */
- (void)addEvent: (NSObject<EventProtocol> *)event
{
	[_events addObject: event];
#if INCLUDE_FEATURE(Extra_Animation)
	const NSInteger idx = _events.count-1;
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
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
			[_zapListController release];
			_zapListController = nil;
			_zapListController = [[ServiceZapListController showAlert:self fromTabBar:self.tabBarController.tabBar] retain];
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
	NSURL *url = nil;

	[_zapListController release];
	_zapListController = nil;

	if(selectedAction == zapActionRemote)
	{
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
		return;
	}

	streamingURL = [[RemoteConnectorObject sharedRemoteConnector] getStreamURLForService:_service];
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
		return;
	}

	switch(selectedAction)
	{
		default: break;
		case zapActionOPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"oplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionOPlayerLite:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"oplayerlite://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionBuzzPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"buzzplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionYxplayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"yxp://%@", [streamingURL absoluteURL]]];
			break;
	}
	if(url)
		[[UIApplication sharedApplication] openURL:url];
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
