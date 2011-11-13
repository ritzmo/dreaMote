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
#import "NSString+URLEncode.h"
#import "UITableViewCell+EasyInit.h"

#import "ServiceZapListController.h"

#import "DisplayCell.h"
#import "EventTableViewCell.h"
#import "ServiceTableViewCell.h"
#import "CellTextView.h"

#import "MKStoreManager.h"

@interface  CurrentViewController()
- (UITextView *)newSummary: (NSObject<EventProtocol> *)event;
- (UIButton *)createButtonForSelector:(SEL)selector withImage:(NSString *)imageName;
#if INCLUDE_FEATURE(Ads)
- (void)createAdBannerView;
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, strong) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
@end

@interface CurrentViewController(IMDb)
- (void)openIMDbNow:(id)sender;
- (void)openIMDbNext:(id)sender;
@end

@interface CurrentViewController(Streaming)
- (void)openOPlayer:(id)sender;
- (void)openOPlayerLite:(id)sender;
- (void)openBuzzPlayer:(id)sender;
- (void)openYxplayer:(id)sender;
- (void)openGoodplayer:(id)sender;
- (void)openAcePlayer:(id)sender;
@end

@implementation CurrentViewController

#if INCLUDE_FEATURE(Ads)
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
		_xmlReader = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
}

/* layout */
- (void)loadView
{
	[self loadGroupedTableView];
	_tableView.delegate = self;
	_tableView.dataSource = self;

#if INCLUDE_FEATURE(Ads)
	if(![MKStoreManager isFeaturePurchased:kAdFreePurchase])
		[self createAdBannerView];
#endif
	[self theme];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
#if INCLUDE_FEATURE(Ads)
	[_adBannerView setDelegate:nil];
	_adBannerView = nil;
#endif
	[super viewDidUnload];
}

- (UITextView *)newSummary: (NSObject<EventProtocol> *)event
{
	UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	myTextView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	myTextView.backgroundColor = [DreamoteConfiguration singleton].groupedTableViewCellColor; // to optimize drawing set a background color
	myTextView.textColor = [DreamoteConfiguration singleton].textColor;
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.editable = NO;
	
	NSString *description = event.edescription;
	if(description != nil)
		myTextView.text = description;
	else
		myTextView.text = @"";

	return myTextView;
}

- (UIButton *)createButtonForSelector:(SEL)selector withImage:(NSString *)imageName
{
	const CGRect frame = CGRectMake(0, 0, kUIRowHeight, kUIRowHeight);
	UIButton *button = [[UIButton alloc] initWithFrame: frame];
	if(imageName)
	{
		UIImage *image = [UIImage imageNamed:imageName];
		[button setImage:image forState:UIControlStateNormal];
	}
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

	return button;
}

- (void)fetchData
{
	BaseXMLReader *newReader = nil;
	@try {
		_reloading = YES;
		newReader = [[RemoteConnectorObject sharedRemoteConnector] getCurrent:self];
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		[e raise];
#endif
	}
	_xmlReader = newReader;
}

- (void)emptyData
{
	_service = nil;
	_now = nil;
	_next = nil;
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
#endif
	_nowSummary = nil;
	_nextSummary = nil;
	_xmlReader = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	_reloading = NO;
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
#else
	[_tableView reloadData];
#endif
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService: (NSObject<ServiceProtocol> *)service
{
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
		_nowSummary = [self newSummary: event];
	}
	else
	{
		_next = [event copy];
		_nextSummary = [self newSummary: event];
	}
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	if([cell respondsToSelector:@selector(view)]
	   && [((DisplayCell *)cell).view respondsToSelector:@selector(sendActionsForControlEvents:)])
	{
		[(UIButton *)((DisplayCell *)cell).view sendActionsForControlEvents: UIControlEventTouchUpInside];
	}
	return nil;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
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
		{
			NSInteger rows = 1;

			if(_service && _service.valid && [ServiceZapListController canStream])
			{
				if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
					++rows;
				if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
					++rows;
				if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
					++rows;
				if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]])
					++rows;
				if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]])
					++rows;
				if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]])
					++rows;
			}
			return rows;
		}
		case 1:
			if(_now == nil)
				return 0;
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"imdb:///"]])
				return 3;
			return 2;
		case 2:
			if(_next == nil)
				return 0;
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"imdb:///"]])
				return 3;
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
			NSInteger row = indexPath.row;

			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]] && row > 0)
				++row;
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]] && row > 1)
				++row;
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]] && row > 2)
				++row;
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]] && row > 3)
				++row;
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"goodplayer:///"]] && row > 4)
				++row;
			//if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aceplayer:///"]] && row > 5)
			//	++row;

			switch(row)
			{
				case 0:
					sourceCell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
					[(ServiceTableViewCell *)sourceCell setRoundedPicons:YES];
					((ServiceTableViewCell *)sourceCell).service = _service;
					sourceCell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 1:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)sourceCell).nameLabel.text = @"OPlayer";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openOPlayer:) withImage:nil];
					break;
				case 2:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)sourceCell).nameLabel.text = @"OPlayer Lite";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openOPlayerLite:) withImage:nil];
					break;
				case 3:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)sourceCell).nameLabel.text = @"BUZZ Player";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openBuzzPlayer:) withImage:nil];
					break;
				case 4:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)sourceCell).nameLabel.text = @"yxplayer";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openYxplayer:) withImage:nil];
					break;
				case 5:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)sourceCell).nameLabel.text = @"GoodPlayer";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openGoodplayer:) withImage:nil];
					break;
				case 6:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)sourceCell).nameLabel.text = @"AcePlayer";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openAcePlayer:) withImage:nil];
					break;
			}
			sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
			break;
		}
		case 1:
		{
			switch(indexPath.row)
			{
				default:
				case 0:
					sourceCell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];
					((EventTableViewCell *)sourceCell).formatter = _dateFormatter;
					((EventTableViewCell *)sourceCell).event = _now;
					sourceCell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 1:
					sourceCell = [CellTextView reusableTableViewCellInView:tableView withIdentifier:kCellTextView_ID];
					((CellTextView *)sourceCell).view = _nowSummary;
					break;
				case 2:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
					((DisplayCell *)sourceCell).nameLabel.text = @"IMDb";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openIMDbNow:) withImage:nil];
					break;
			}
			break;
		}
		case 2:
		{
			switch(indexPath.row)
			{
				default:
				case 0:
					sourceCell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];
					((EventTableViewCell *)sourceCell).formatter = _dateFormatter;
					((EventTableViewCell *)sourceCell).event = _next;
					sourceCell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 1:
					sourceCell = [CellTextView reusableTableViewCellInView:tableView withIdentifier:kCellTextView_ID];
					((CellTextView *)sourceCell).view = _nextSummary;
					break;
				case 2:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
					((DisplayCell *)sourceCell).nameLabel.text = @"IMDb";
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openIMDbNext:) withImage:nil];
					break;
			}
			break;
		}
		default:
			break;
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:sourceCell inTableView:tableView];;
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	if(!_reloading)
	{
		// empty again, sometimes now/next gets stuck
		[self emptyData];

		// Run this in our "temporary" queue
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCurrent])
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}

#if INCLUDE_FEATURE(Ads)
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
#if INCLUDE_FEATURE(Ads)
	[self fixupAdView:toInterfaceOrientation];
#endif
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
	Class classAdBannerView = NSClassFromString(@"ADBannerView");
	if(classAdBannerView != nil)
	{
		self.adBannerView = [[classAdBannerView alloc] initWithFrame:CGRectZero];
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

#pragma mark IMDb

- (void)openIMDbNow:(id)sender
{
	NSString *encoded = [_now.title urlencode];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"imdb:///find?q=%@", encoded]];

	[[UIApplication sharedApplication] openURL:url];
}

- (void)openIMDbNext:(id)sender
{
	NSString *encoded = [_next.title urlencode];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"imdb:///find?q=%@", encoded]];

	[[UIApplication sharedApplication] openURL:url];
}

#pragma mark Streaming

- (void)openStreamWithAction:(zapAction)action
{
	NSURL *streamingURL = [[RemoteConnectorObject sharedRemoteConnector] getStreamURLForService:_service];
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
		[ServiceZapListController openStream:streamingURL withAction:action];
}

- (void)openOPlayer:(id)sender
{
	[self openStreamWithAction:zapActionOPlayer];
}

- (void)openOPlayerLite:(id)sender
{
	[self openStreamWithAction:zapActionOPlayerLite];
}

- (void)openBuzzPlayer:(id)sender
{
	[self openStreamWithAction:zapActionBuzzPlayer];
}

- (void)openYxplayer:(id)sender
{
	[self openStreamWithAction:zapActionYxplayer];
}

- (void)openGoodplayer:(id)sender
{
	[self openStreamWithAction:zapActionGoodPlayer];
}

- (void)openAcePlayer:(id)sender
{
	[self openStreamWithAction:zapActionAcePlayer];
}

@end
