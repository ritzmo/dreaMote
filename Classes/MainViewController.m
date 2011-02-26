//
//  MainViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MainViewController.h"

#import "AppDelegate.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "BouquetSplitViewController.h"
#import "MediaPlayerSplitViewController.h"
#import "MovieSplitViewController.h"
#import "TimerSplitViewController.h"

#import "BouquetListController.h"
#import "ConfigListController.h"
#import "ConfigViewController.h"
#import "CurrentViewController.h"
#import "OtherListController.h"
#import "ServiceListController.h"
#import "SimpleRCEmulatorController.h"
#import "TimerListController.h"

@interface MainViewController()
- (void)handleReconnect: (NSNotification *)note;
- (BOOL)checkConnection;
#if IS_LITE()
- (void)createAdBannerView;
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, retain) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
@end

@implementation MainViewController

@synthesize myTabBar;
#if IS_LITE()
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;
#endif

- (id)init
{
	if((self = [super init]))
	{
		//
	}
	return self;
}

- (void)dealloc
{
	[myTabBar release];
	[menuList release];
	[_bouquetController release];
	[_currentController release];
	[_mediaplayerController release];
	[_movieController release];
	[_otherController release];
	[_rcController release];
	[_serviceController release];
	[_timerController release];
#if IS_LITE()
	[_adBannerView release];
#endif

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	if([RemoteConnectorObject isConnected])
		[[RemoteConnectorObject sharedRemoteConnector] freeCaches];

	[super didReceiveMemoryWarning];
}

- (void)awakeFromNib
{
	UINavigationController *navController = nil;
	UIViewController *viewController = nil;
	UIImage *image = nil;
	menuList = [[NSMutableArray alloc] init];

	// create our view controllers - we will encase each title and view controller pair in a NSDictionary
	// and add it to a mutable array.  If you want to add more pages, simply call "addObject" on "menuList"
	// with an additional NSDictionary.  Note we use NSLocalizedString to load a localized version of its title.

	_currentController = [[CurrentViewController alloc] init];
	if(IS_IPAD())
	{
		_bouquetController = [[BouquetSplitViewController alloc] init];
		_timerController = [[TimerSplitViewController alloc] init];
		_mediaplayerController = [[MediaPlayerSplitViewController alloc] init];
		_movieController = [[MovieSplitViewController alloc] init];
	}
	else
	{
		viewController = [[BouquetListController alloc] init];
		_bouquetController = [[UINavigationController alloc] initWithRootViewController: viewController];
		[viewController release];
		viewController = [[ServiceListController alloc] init];
		_serviceController = [[UINavigationController alloc] initWithRootViewController: viewController];
		[viewController release];
		viewController = [[TimerListController alloc] init];
		_timerController = [[UINavigationController alloc] initWithRootViewController: viewController];
		[viewController release];
	}
	_rcController = nil;
	_otherController = [[OtherListController alloc] init];
	navController = [[UINavigationController alloc] initWithRootViewController: _otherController];

	// assign tab bar images
	image = [UIImage imageNamed: @"bouquet.png"];
	_bouquetController.tabBarItem.image = image;
	_serviceController.tabBarItem.image = image;
	image = [UIImage imageNamed: @"timer.png"];
	_timerController.tabBarItem.image = image;
	image = [UIImage imageNamed: @"current.png"];
	_currentController.tabBarItem.image = image;
	image = [UIImage imageNamed: @"others.png"];
	_otherController.tabBarItem.image = image;

	[menuList addObject: _timerController];
	[menuList addObject: navController];

	[navController release];

	[self setViewControllers: menuList];
	self.delegate = self;

#if IS_LITE()
	[self createAdBannerView];
#endif

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReconnect:) name:kReconnectNotification object:nil];
}

#pragma mark -
#pragma mark MainViewController private methods
#pragma mark -

- (void)handleReconnect: (NSNotification *)note
{
	const id connId = [[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection];
	if(![RemoteConnectorObject isConnected])
		if(![RemoteConnectorObject connectTo: [connId integerValue]])
			return;
	const BOOL isSingleBouquet =
		[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
		&& (
			[RemoteConnectorObject isSingleBouquet] ||
			![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets]);
	const BOOL useSimpleRemote = [[NSUserDefaults standardUserDefaults] boolForKey: kPrefersSimpleRemote];

	// Toggle single bouquet mode
	if(!IS_IPAD() && isSingleBouquet)
	{
		if(![menuList containsObject: _serviceController])
		{
			[menuList removeObject: _bouquetController];
			[menuList insertObject: _serviceController atIndex: 0];
		}
	}
	else
	{
		if(![menuList containsObject: _bouquetController])
		{
			[menuList removeObject: _serviceController];
			[menuList insertObject: _bouquetController atIndex: 0];
		}
	}

	// Add/Remove currently playing
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCurrent])
	{
		if(![menuList containsObject: _currentController])
		{
			[menuList insertObject: _currentController atIndex: 1];
		}
	}
	else
	{
		[menuList removeObject: _currentController];
	}

	if(IS_IPAD())
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMediaPlayer])
		{
			if(![menuList containsObject: _mediaplayerController])
			{
				[menuList insertObject: _mediaplayerController atIndex: 2];
			}
		}
		else
		{
			[menuList removeObject: _mediaplayerController];
		}

		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordInfo])
		{
			if(![menuList containsObject: _movieController])
			{
				[menuList insertObject: _movieController atIndex: 2];
			}
		}
		else
		{
			[menuList removeObject: _movieController];
		}
	}

	// RC second to last
	[menuList removeObject: _rcController];
	[_rcController release];
	if(useSimpleRemote)
		_rcController = [[SimpleRCEmulatorController alloc] init];
	else
		_rcController = [[RemoteConnectorObject sharedRemoteConnector] newRCEmulator];
	[menuList insertObject: _rcController atIndex: [menuList count] - 2];
	UIImage *image = [UIImage imageNamed: @"remote.png"];
	_rcController.tabBarItem.image = image;

	[self setViewControllers: menuList];
	// initial load
	if(self.selectedIndex == NSNotFound)
		self.selectedViewController = [menuList lastObject];
}

- (BOOL)checkConnection
{
	// ignore if import in progress
	if(((AppDelegate *)[UIApplication sharedApplication].delegate).importing) return YES;

	// handleReconnect makes sure that a connection is established unless impossible
	if(![RemoteConnectorObject isConnected])
	{
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"You need to configure this application before you can use it.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];

		// dialog (probably) already visible
		if([self.selectedViewController isEqual:[menuList lastObject]]
		   && [_otherController.navigationController.visibleViewController isKindOfClass:[ConfigViewController class]])
		{
			return NO;
		}

		ConfigViewController *targetViewController = [ConfigViewController newConnection];
		targetViewController.mustSave = YES;
		self.selectedViewController = [menuList lastObject];
		[_otherController.navigationController pushViewController: targetViewController animated: YES];
		[self.selectedViewController viewWillAppear:YES];
		[self.selectedViewController viewDidAppear:YES];
		[targetViewController release];
		return NO;
	}

	else if([[NSUserDefaults standardUserDefaults] boolForKey: kConnectionTest]
			&& ![[RemoteConnectorObject sharedRemoteConnector] isReachable])
	{
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"Remote host unreachable!\nPlease check your network settings or connect to another host.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];

		self.selectedViewController = [menuList lastObject];
		// config list already open, (eventually) go back to it and abort
		if([[_otherController.navigationController viewControllers] containsObject: _otherController.configListController])
		{
			[_otherController.navigationController popToViewController:(UIViewController *)_otherController.configListController animated:YES];
		}
		// push config list
		else
		{
			[_otherController.navigationController pushViewController:(UIViewController *)_otherController.configListController animated:YES];
			[self.selectedViewController viewWillAppear:YES];
			[self.selectedViewController viewDidAppear:YES];
		}
		return NO;
	}
	return YES;
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
#if IS_LITE()
	[self fixupAdView:[UIDevice currentDevice].orientation];
#endif
	[self handleReconnect: nil];
	[self.selectedViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	if([self checkConnection])
		[self.selectedViewController viewDidAppear:animated];
}

/* rotation depends on active view */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIViewController *cur = self.selectedViewController;
	if(cur == nil)
		return YES;
	else
		return [cur shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#if IS_LITE()
	if(_adBannerViewIsVisible)
		[self fixupAdView:[UIDevice currentDevice].orientation];
#endif
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark UITabBarController delegates

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
	[self.selectedViewController viewWillDisappear:YES];
	[self.selectedViewController viewDidDisappear:YES];

	if(![self checkConnection])
	{
		self.selectedViewController = [menuList lastObject];
		[self.selectedViewController viewWillAppear:YES];
		[self.selectedViewController viewDidAppear:YES];
		return NO;
	}

	return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
	[viewController viewWillAppear:YES];
	[viewController viewDidAppear:YES];
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
	return [self getBannerHeight:[UIDevice currentDevice].orientation];
}

- (void)createAdBannerView
{
	Class classAdBannerView = NSClassFromString(@"ADBannerView");
	if(classAdBannerView != nil)
	{
		self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectZero] autorelease];
		[_adBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects:
														  ADBannerContentSizeIdentifierPortrait,
														  ADBannerContentSizeIdentifierLandscape,
														  nil]];
		if(UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation))
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
			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			CGSize cgSize = [[UIScreen mainScreen] bounds].size;
			adBannerViewFrame.origin.y = cgSize.height - self.tabBar.frame.size.height - [self getBannerHeight:toInterfaceOrientation];
#else
			adBannerViewFrame.origin.y = 0;
#endif
			[_adBannerView setFrame:adBannerViewFrame];

			CGRect contentViewFrame = self.selectedViewController.view.frame;
#ifdef __BOTTOM_AD__
			contentViewFrame.origin.y = 0;
#else
			contentViewFrame.origin.y = [self getBannerHeight:toInterfaceOrientation];
#endif
			contentViewFrame.size.height = self.view.frame.size.height - self.tabBar.frame.size.height - [self getBannerHeight:toInterfaceOrientation];
			self.selectedViewController.view.frame = contentViewFrame;
		}
		else
		{
			CGRect adBannerViewFrame = [_adBannerView frame];
			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			CGSize cgSize = [[UIScreen mainScreen] bounds].size;
			adBannerViewFrame.origin.y = cgSize.height - self.tabBar.frame.size.height;
#else
			adBannerViewFrame.origin.y = 0;
#endif
			[_adBannerView setFrame:adBannerViewFrame];

			CGRect contentViewFrame = self.selectedViewController.view.frame;
			contentViewFrame.origin.y = 0;
			contentViewFrame.size.height = self.view.frame.size.height - self.tabBar.frame.size.height;
			self.selectedViewController.view.frame = contentViewFrame;
		}
		[UIView commitAnimations];
	}
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	if(!_adBannerViewIsVisible)
	{
		_adBannerViewIsVisible = YES;
		[self fixupAdView:[UIDevice currentDevice].orientation];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	if(_adBannerViewIsVisible)
	{
		_adBannerViewIsVisible = NO;
		[self fixupAdView:[UIDevice currentDevice].orientation];
	}
}
#endif

@end
