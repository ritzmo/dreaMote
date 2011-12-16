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
#import "OtherSplitViewController.h"
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
@end

@implementation MainViewController

@synthesize myTabBar;

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
	[self stopObservingThemeChanges];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
	if([RemoteConnectorObject isConnected])
		[[RemoteConnectorObject sharedRemoteConnector] freeCaches];

	[super didReceiveMemoryWarning];
}

- (void)awakeFromNib
{
	const BOOL isIpad = IS_IPAD();
	UIViewController *viewController = nil;
	UIImage *image = nil;
	menuList = [[NSMutableArray alloc] init];

	// create our view controllers - we will encase each title and view controller pair in a NSDictionary
	// and add it to a mutable array.  If you want to add more pages, simply call "addObject" on "menuList"
	// with an additional NSDictionary.  Note we use NSLocalizedString to load a localized version of its title.

	_currentController = [[CurrentViewController alloc] init];
	if(isIpad)
	{
		_bouquetController = [[BouquetSplitViewController alloc] init];
		_timerController = [[TimerSplitViewController alloc] init];
		_mediaplayerController = [[MediaPlayerSplitViewController alloc] init];
		_movieController = [[MovieSplitViewController alloc] init];

		// NOTE: consistency is more important to us than the little space it takes on the ipad
		_currentController = [[UINavigationController alloc] initWithRootViewController:_currentController];
	}
	else
	{
		viewController = [[BouquetListController alloc] init];
		_bouquetController = [[UINavigationController alloc] initWithRootViewController: viewController];
		viewController = [[ServiceListController alloc] init];
		_serviceController = [[UINavigationController alloc] initWithRootViewController: viewController];
		viewController = [[TimerListController alloc] init];
		_timerController = [[UINavigationController alloc] initWithRootViewController: viewController];
	}
	_rcController = nil;
	[menuList addObject:_timerController];

	if(isIpad)
	{
		_otherController = [[OtherSplitViewController alloc] init];
		[menuList addObject:_otherController];
	}
	else
	{
		_otherController = [[OtherListController alloc] init];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_otherController];
		[menuList addObject:navController];
	}

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

	self.viewControllers = menuList;
	self.selectedViewController = [menuList lastObject];
	self.delegate = self;

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReconnect:) name:kReconnectNotification object:nil];
}

- (void)theme
{
	[[DreamoteConfiguration singleton] styleTabBar:self.tabBar];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	[super viewDidUnload];
}

#pragma mark -
#pragma mark MainViewController private methods
#pragma mark -

- (void)handleReconnect: (NSNotification *)note
{
	@synchronized(self) { // begin synchronized
	if(![RemoteConnectorObject isConnected])
	{
		const id connId = [[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection];
		if(![RemoteConnectorObject connectTo:[connId integerValue] inBackground:YES])
		{
			return;
		}
		else
		{
			const NSError *error = nil;
			if(![[RemoteConnectorObject sharedRemoteConnector] isReachable:&error])
			{
				UIAlertView *notification = [[UIAlertView alloc]
											 initWithTitle:NSLocalizedString(@"Error", @"")
												   message:[error localizedDescription]
												  delegate:nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
				[notification show];
			}
		}
	}
	const NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
	const BOOL isSingleBouquet =
		[sharedRemoteConnector hasFeature: kFeaturesSingleBouquet]
		&& (
			[RemoteConnectorObject isSingleBouquet] ||
			![sharedRemoteConnector hasFeature: kFeaturesBouquets]);
	const BOOL useSimpleRemote = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefersSimpleRemote];
	const BOOL isIpad = IS_IPAD();

	// Toggle single bouquet mode
	if(!isIpad && isSingleBouquet)
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
	if([sharedRemoteConnector hasFeature: kFeaturesCurrent])
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

	if(isIpad)
	{
		if([sharedRemoteConnector hasFeature: kFeaturesMediaPlayer])
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

		if([sharedRemoteConnector hasFeature: kFeaturesRecordInfo])
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
	if(useSimpleRemote || sharedRemoteConnector == nil)
		_rcController = [[SimpleRCEmulatorController alloc] init];
	else
		_rcController = [sharedRemoteConnector newRCEmulator];
	[menuList insertObject: _rcController atIndex: [menuList count] - 2];
	UIImage *image = [UIImage imageNamed: @"remote.png"];
	_rcController.tabBarItem.image = image;

	[self performSelectorOnMainThread:@selector(setViewControllers:) withObject:menuList waitUntilDone:NO];
	} // end synchronized
}

- (BOOL)checkConnection
{
	// ignore if import in progress
	if(APP_DELEGATE.isBusy) return YES;

	// handleReconnect makes sure that a connection is established unless impossible
	if(![RemoteConnectorObject isConnected])
	{
		[_otherController forceConfigDialog];
		self.selectedViewController = [menuList lastObject];
		return NO;
	}
	return YES;
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
	[self handleReconnect: nil];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	welcomeTypes welcomeType = APP_DELEGATE.welcomeType;
	if(welcomeType != welcomeTypeNone)
	{
		AboutDreamoteViewController *welcomeController = [[AboutDreamoteViewController alloc] initWithWelcomeType:welcomeType];
		welcomeController.aboutDelegate = self;
		[self presentModalViewController:welcomeController animated:YES];
	}
	else
		[self checkConnection];

	[super viewDidAppear:animated];
}

/* rotation depends on active view */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIViewController *cur = self.selectedViewController;
	if(cur == nil)
		return YES;
	else
		return [cur shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark AboutDreamoteDelegate delegates

- (void)dismissedAboutDialog
{
	// we need to call this manually on the ipad when the dialog was dismissed
	if(IS_IPAD())
	{
		// check if we are connected, but the primary use is to show the ConfigView if unable to connect
		[self checkConnection];
	}
}

#pragma mark UITabBarController delegates

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
	[RemoteConnectorObject cancelPendingOperations];

	// returns no if not selected
	return [self checkConnection];
}

@end
