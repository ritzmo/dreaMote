//
//  CurrentViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "CurrentViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import "EventTableViewCell.h"
#import "ServiceTableViewCell.h"
#import "CellTextView.h"

@interface  CurrentViewController()
- (UITextView *)newSummary: (NSObject<EventProtocol> *)event;
#if SHOW_ADS()
- (void)createAdBannerView;
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, retain) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
@end

@implementation CurrentViewController

#if SHOW_ADS()
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;
#endif

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Currently playing", @"");
		self.tabBarItem.title = NSLocalizedString(@"Playing", @"TabBar Title of CurrentViewController");
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_now = nil;
		_next = nil;
		_service = nil;
		_currentXMLDoc = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[_now release];
	[_next release];
	[_service release];
	[_dateFormatter release];
	[_currentXMLDoc release];
	[_nowSummary release];
	[_nextSummary release];
#if SHOW_ADS()
	[_adBannerView release];
#endif

	[super dealloc];
}

/* layout */
- (void)loadView
{
	[self loadGroupedTableView];
	_tableView.delegate = self;
	_tableView.dataSource = self;

#if SHOW_ADS()
	[self createAdBannerView];
#endif
	
}

- (UITextView *)newSummary: (NSObject<EventProtocol> *)event
{
	UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	myTextView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.editable = NO;
	
	NSString *description = event.edescription;
	if(description != nil)
		myTextView.text = description;
	else
		myTextView.text = @"";

	return myTextView;
}

- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_currentXMLDoc release];
	@try {
		_reloading = YES;
		_currentXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] getCurrent: self] retain];
	}
	@catch (NSException * e) {
		_currentXMLDoc = nil;
	}
	[pool release];
}

- (void)emptyData
{
	[_service release];
	_service = nil;
	[_now release];
	_now = nil;
	[_next release];
	_next = nil;
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
	[_nowSummary release];
	_nowSummary = nil;
	[_nextSummary release];
	_nextSummary = nil;
	[_currentXMLDoc release];
	_currentXMLDoc = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	_reloading = NO;
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService: (NSObject<ServiceProtocol> *)service
{
	if(_service != nil)
		[_service release];
	_service = [service copy];
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent: (NSObject<EventProtocol> *)event
{
	if(_now == nil)
	{
		_now = [event copy];
		[_nowSummary release];
		_nowSummary = [self newSummary: event];
	}
	else
	{
		if(_next != nil)
			[_next release];
		_next = [event copy];
		[_nextSummary release];
		_nextSummary = [self newSummary: event];
	}
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return NSLocalizedString(@"Service", @"");
		case 1:
			return (_now != nil) ? NSLocalizedString(@"Now", @"") : nil;
		case 2:
			return (_next != nil) ? NSLocalizedString(@"Next", @"") : nil;
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			return 1;
		case 1:
			if(_now == nil)
				return 0;
			return 2;
		case 2:
			if(_next == nil)
				return 0;
			return 2;
		default:
			return 0;
	}
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 1:
		{
			if(_now == nil)
				return 0;
			if(indexPath.row == 1)
				return kTextViewHeight;
			break;
		}
		case 2:
		{
			if(_next == nil)
				return 0;
			if(indexPath.row == 1)
				return kTextViewHeight;
		}
		case 0:
		default:
			break;
	}
	
	return kUIRowHeight;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = nil;

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
		{
			sourceCell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			sourceCell.imageView.layer.masksToBounds = YES;
			sourceCell.imageView.layer.cornerRadius = 5.0f;
			((ServiceTableViewCell *)sourceCell).service = _service;
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case 1:
		{
			if(indexPath.row == 0)
			{
				sourceCell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];
				((EventTableViewCell *)sourceCell).formatter = _dateFormatter;
				((EventTableViewCell *)sourceCell).event = _now;
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
			}
			else
			{
				sourceCell = [CellTextView reusableTableViewCellInView:tableView withIdentifier:kCellTextView_ID];
				((CellTextView *)sourceCell).view = _nowSummary;
				_nowSummary.backgroundColor = sourceCell.backgroundColor;
			}
			break;
		}
		case 2:
		{
			if(indexPath.row == 0)
			{
				sourceCell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];
				((EventTableViewCell *)sourceCell).formatter = _dateFormatter;
				((EventTableViewCell *)sourceCell).event = _next;
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
			}
			else
			{
				sourceCell = [CellTextView reusableTableViewCellInView:tableView withIdentifier:kCellTextView_ID];
				((CellTextView *)sourceCell).view = _nextSummary;
				_nextSummary.backgroundColor = sourceCell.backgroundColor;
			}
			break;
		}
		default:
			break;
	}
	
	return sourceCell;
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	if(!_reloading)
	{
		// empty again, sometimes now/next gets stuck
		[self emptyData];

		// Spawn a thread to fetch the event data so that the UI is not blocked while the
		// application parses the XML file.
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCurrent])
			[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}

#if SHOW_ADS()
	[self fixupAdView:self.interfaceOrientation];
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	if(!_reloading)
		[self emptyData];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/* about to rotate */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
#if SHOW_ADS()
	[self fixupAdView:toInterfaceOrientation];
#endif
}

#pragma mark ADBannerViewDelegate
#if SHOW_ADS()

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
