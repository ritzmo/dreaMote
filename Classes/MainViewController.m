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

#import "MainTableViewCell.h"

#import "AboutViewController.h"
#import "BouquetListController.h"
#import "ConfigViewController.h"
#import "ConfigListController.h"
#import "ControlViewController.h"
#import "CurrentViewController.h"
#import "EventSearchListController.h"
#import "MessageViewController.h"
#import "MovieListController.h"
#import "ServiceListController.h"
#import "SignalViewController.h"
#import "TimerListController.h"
#import "OtherListController.h"

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
	[_currentController release];
	[_bouquetController release];
	[_serviceController release];
	[_timerController release];
	[_rcController release];
	[_otherController release];

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
	menuList = [[NSMutableArray alloc] init];

	// create our view controllers - we will encase each title and view controller pair in a NSDictionary
	// and add it to a mutable array.  If you want to add more pages, simply call "addObject" on "menuList"
	// with an additional NSDictionary.  Note we use NSLocalizedString to load a localized version of its title.

	_currentController = [[CurrentViewController alloc] init];
	_bouquetController = [[BouquetListController alloc] init];
	_serviceController = [[ServiceListController alloc] init];
	_timerController = [[TimerListController alloc] init];
	_rcController = nil;
	_otherController = [[OtherListController alloc] init];

	[menuList addObject: _timerController];
	[menuList addObject: _otherController];

	[self setViewControllers: menuList];
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
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
	if(isSingleBouquet)
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
	
	// RC second to last
	[menuList removeObject: _rcController];
	_rcController = [[RemoteConnectorObject sharedRemoteConnector] createRCEmulator];
	[menuList insertObject: _rcController atIndex: [menuList count] - 2];
	
	[self setViewControllers: menuList];
}

- (void)viewDidAppear:(BOOL)animated
{
	// viewWillAppear makes sure that a connection is established unless impossible
	if(![RemoteConnectorObject isConnected])
	{
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"You need to configure this application before you can use it.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//[notification show];
		[notification release];

		UIViewController *targetViewController = [ConfigViewController newConnection];
		//self.selectedIndex = [menuList count] - 1;
		//[_otherController.navigationController pushViewController: targetViewController animated: YES];
		[targetViewController release];
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
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
