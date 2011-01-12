//
//  MainViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MainViewController.h"

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
#import "TimerListController.h"

@interface MainViewController (Private)
- (void)handleReconnect: (NSNotification *)note;
- (BOOL)checkConnection;
@end

@implementation MainViewController

@synthesize myTabBar;

- (id)init
{
	if((self = [super init]))
	{
		// make the title of this page the same as the title of this app
		self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
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
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordInfo])
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
	_rcController = [[RemoteConnectorObject sharedRemoteConnector] newRCEmulator];
	[menuList insertObject: _rcController atIndex: [menuList count] - 2];
	UIImage *image = [UIImage imageNamed: @"remote.png"];
	_rcController.tabBarItem.image = image;

	[self setViewControllers: menuList];
	// initial load
	if(self.selectedIndex == NSNotFound)
		self.selectedIndex = 0;
}

- (BOOL)checkConnection
{
	// handleReconnect makes sure that a connection is established unless impossible
	if(![RemoteConnectorObject isConnected])
	{
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"You need to configure this application before you can use it.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];

		ConfigViewController *targetViewController = [ConfigViewController newConnection];
		targetViewController.mustSave = YES;
		self.selectedIndex = [menuList count] - 1;
		[_otherController.navigationController pushViewController: targetViewController animated: YES];
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

		self.selectedIndex = [menuList count] - 1;
		if(!_otherController.configListController)
		{
			ConfigListController *configListController = [[ConfigListController alloc] init];
			_otherController.configListController = configListController;
			[configListController release];
		}
		[_otherController.navigationController pushViewController: (UIViewController *)_otherController.configListController animated: YES];
		return NO;
	}
	return YES;
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
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
	return [self.selectedViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark UITabBarController delegates

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
	if(![self checkConnection])
	{
		self.selectedIndex = [menuList count] - 1;
		return NO;
	}

	[self.selectedViewController viewWillDisappear:YES];
	[self.selectedViewController viewDidDisappear:YES];
	return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
	[viewController viewWillAppear:YES];
	[viewController viewDidAppear:YES];
}

@end
