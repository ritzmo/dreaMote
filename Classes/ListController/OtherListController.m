//
//  OtherListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "OtherListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import "MainTableViewCell.h"

#import "AboutViewController.h"
#import "AboutDreamoteViewController.h"
#if IS_FULL()
	#import "AutoTimerListController.h"
#endif
#import "BouquetListController.h"
#import "ConfigViewController.h"
#import "ConfigListController.h"
#import "ControlViewController.h"
#import "CurrentViewController.h"
#import "EPGRefreshViewController.h"
#import "EventSearchListController.h"
#import "MessageViewController.h"
#import "MovieListController.h"
#import "LocationListController.h"
#import "ServiceListController.h"
#import "SignalViewController.h"
#import "SleepTimerViewController.h"
#import "TimerListController.h"
#import "MediaPlayerController.h"
#import "PackageManagerListController.h"

@interface OtherListController()
- (void)handleReconnect: (NSNotification *)note;
/*!
 @brief display about dialog
 @param sender ui element
 */
- (void)aboutDreamoteAction: (id)sender;
@end

@implementation OtherListController

@synthesize myTableView;

- (id)init
{
	if((self = [super init]))
	{
		self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
		self.tabBarItem.title = NSLocalizedString(@"More", @"Tab Title of OtherListController");
		_configListController = nil;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
	_aboutDreamoteViewController = nil;

	if([RemoteConnectorObject isConnected])
		[[RemoteConnectorObject sharedRemoteConnector] freeCaches];

    [super didReceiveMemoryWarning];
}

/* getter of (readonly) configListController property */
- (ConfigListController *)configListController
{
	if(!_configListController)
		_configListController = [[ConfigListController alloc] init];
	return _configListController;
}

- (void)viewDidLoad
{
	menuList = [[NSMutableArray alloc] init];

	// create our view controllers - we will encase each title and view controller pair in a NSDictionary
	// and add it to a mutable array.  If you want to add more pages, simply call "addObject" on "menuList"
	// with an additional NSDictionary.  Note we use NSLocalizedString to load a localized version of its title.

	UIViewController *targetViewController;

	targetViewController = [[AboutViewController alloc] init];
	_aboutDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
						NSLocalizedString(@"About Receiver", @"Title of About Receiver in Other List"), @"title",
						NSLocalizedString(@"Information on software and tuners", @"Explaination of About Receiver in Other List"), @"explainText",
						targetViewController, @"viewController",
						nil];

#if IS_FULL()
	targetViewController = [[AutoTimerListController alloc] init];
	_autotimerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"AutoTimer-Plugin", @"Title of AutoTimer in Other List"), @"title",
						 NSLocalizedString(@"Add and edit AutoTimers", @"Explaination of AutoTimer in Other List"), @"explainText",
						 targetViewController, @"viewController",
						 nil];
#endif

	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Settings", @"Title of Settings in Other List"), @"title",
						 NSLocalizedString(@"Change configuration and edit known hosts", @"Explaination of Settings in Other List"), @"explainText",
						 self.configListController, @"viewController",
						 nil]];

	targetViewController = [[EPGRefreshViewController alloc] init];
	_epgrefreshDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"EPGRefresh-Plugin", @"Title of EPGRefresh in Other List"), @"title",
							  NSLocalizedString(@"Settings of EPGRefresh-Plugin", @"Explaination of EPGRefresh in Other List"), @"explainText",
							  targetViewController, @"viewController",
							  nil];

	targetViewController = [[EventSearchListController alloc] init];
	_eventSearchDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							NSLocalizedString(@"Search EPG", @"Title of Event Search in Other List"), @"title",
							NSLocalizedString(@"Search EPG for event titles", @"Explaination of Event Search in Other List"), @"explainText",
							targetViewController, @"viewController",
							nil];

	targetViewController = [[SignalViewController alloc] init];
	_signalDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							   NSLocalizedString(@"Signal Finder", @"Title of Signal Finder in Other List"), @"title",
							   NSLocalizedString(@"Displays current SNR/AGC", @"Explaination of Signal Finder in Other List"), @"explainText",
							   targetViewController, @"viewController",
							   nil];

	if(!IS_IPAD())
	{
		targetViewController = [[LocationListController alloc] init];
		_locationsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							NSLocalizedString(@"Recording Locations", @"Title of Location List in Other List"), @"title",
							NSLocalizedString(@"Show recording locations", @"Explaination of Location List in Other List"), @"explainText",
							targetViewController, @"viewController",
							nil];

		targetViewController = [[MovieListController alloc] init];
		_recordDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							NSLocalizedString(@"Movies", @"Title of Movie List in Other List"), @"title",
							NSLocalizedString(@"Recorded Movies", @"Explaination of Movie List in Other List"), @"explainText",
							targetViewController, @"viewController",
							nil];
	}

	targetViewController = [[MediaPlayerController alloc] init];
	_mediaPlayerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								   NSLocalizedString(@"Media Player", @"Title of Media Player in Other List"), @"title",
								   NSLocalizedString(@"Control the remote media player", @"Explaination of Media Player in Other List"), @"explainText",
								   targetViewController, @"viewController",
								   nil];

	targetViewController = [[ControlViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						NSLocalizedString(@"Control", @"Title of Control View in Other List"), @"title",
						NSLocalizedString(@"Control Powerstate and Volume", @"Explaination of Control View in Other List"), @"explainText",
						targetViewController, @"viewController",
						nil]];

	targetViewController = [[MessageViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Messages", @"Title of Message View in Other List"), @"title",
						 NSLocalizedString(@"Send short Messages", @"Explaination of Message View in Other List"), @"explainText",
						 targetViewController, @"viewController",
						 nil]];

	targetViewController = [[SleepTimerViewController alloc] init];
	_sleeptimerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"Sleep Timer", @"Title of Sleep Timer in Other List"), @"title",
							  NSLocalizedString(@"Edit and (de)activate Sleep Timer", @"Explaination of Sleep Timer in Other List"), @"explainText",
							  targetViewController, @"viewController",
							  nil];

	targetViewController = [[PackageManagerListController alloc] init];
	_packageManagerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"Package Manager", @"Title of Package Manager in Other List"), @"title",
							  NSLocalizedString(@"Install/Update/Remove packages", @"Explaination of Package Manager in Other List"), @"explainText",
							  targetViewController, @"viewController",
							  nil];

	// Add the "About" button to the navigation bar
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", @"About Button Text") style:UIBarButtonItemStylePlain target:self action:@selector(aboutDreamoteAction:)];
	self.navigationItem.leftBarButtonItem = buttonItem;

	myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	if(IS_IPAD())
		myTableView.rowHeight = kUIRowHeight;

	// setup our list view to autoresizing in case we decide to support autorotation along the other UViewControllers
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReconnect:) name:kReconnectNotification object:nil];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.myTableView = nil;
	_aboutDreamoteViewController = nil;
#if IS_FULL()
	_autotimerDictionary = nil;
#endif
	_configListController = nil;
	_epgrefreshDictionary = nil;
	_eventSearchDictionary = nil;
	_mediaPlayerDictionary = nil;
	_locationsDictionary = nil;
	_recordDictionary = nil;
	_signalDictionary = nil;
	_sleeptimerDictionary = nil;
	_packageManagerDictionary = nil;
	[menuList removeAllObjects];

	[super viewDidUnload];
}

- (void)aboutDreamoteAction: (id)sender
{
	if(_aboutDreamoteViewController == nil)
		_aboutDreamoteViewController = [[AboutDreamoteViewController alloc] init];
	[self.navigationController presentModalViewController: _aboutDreamoteViewController animated:YES];
}

- (void)handleReconnect: (NSNotification *)note
{
	[self viewWillAppear:YES];
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:YES];

	const id connId = [[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection];
	if(![RemoteConnectorObject isConnected])
		if(![RemoteConnectorObject connectTo: [connId integerValue]])
			return;

	BOOL reload = NO;
	/* The menu reorganization might be buggy, this should be redone
	   as it was a bad hack to begin with */
	// Add/Remove Record
	if(!IS_IPAD())
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordInfo])
		{
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
			{
				if(![menuList containsObject: _locationsDictionary])
				{
					[menuList removeObject:_recordDictionary];
					[menuList insertObject:_locationsDictionary atIndex: 2];
					reload = YES;
				}
			}
			else
			{
				if(![menuList containsObject: _recordDictionary])
				{
					[menuList removeObject:_locationsDictionary];
					[menuList insertObject:_recordDictionary atIndex: 2];
					reload = YES;
				}
			}
		}
		else
		{
			if([menuList containsObject: _recordDictionary]
			   || [menuList containsObject: _locationsDictionary])
			{
				[menuList removeObject: _recordDictionary];
				[menuList removeObject: _locationsDictionary];
				reload = YES;
			}
		}
		
		// Add/Remove Media Player
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMediaPlayer])
		{
			if(![menuList containsObject: _mediaPlayerDictionary])
			{
				[menuList insertObject: _mediaPlayerDictionary atIndex: 2];
				reload = YES;
			}
		}
		else
		{
			if([menuList containsObject: _mediaPlayerDictionary])
			{
				[menuList removeObject: _mediaPlayerDictionary];
				reload = YES;
			}
		}
	}

	// Add/Remove Signal Finder
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSatFinder])
	{
		if(![menuList containsObject: _signalDictionary])
		{
			[menuList insertObject: _signalDictionary atIndex: (IS_IPAD()) ? 3 : 4];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _signalDictionary])
		{
			[menuList removeObject: _signalDictionary];
			reload = YES;
		}
	}

	// Add/Remove Package Manager
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesPackageManagement])
	{
		if(![menuList containsObject: _packageManagerDictionary])
		{
			[menuList insertObject: _packageManagerDictionary atIndex: (IS_IPAD()) ? 4 : 5];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _packageManagerDictionary])
		{
			[menuList removeObject: _packageManagerDictionary];
			reload = YES;
		}
	}

	// Add/Remove Sleep Timer
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSleepTimer])
	{
		if(![menuList containsObject: _sleeptimerDictionary])
		{
			[menuList insertObject: _sleeptimerDictionary atIndex: (IS_IPAD()) ? 4 : 5];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _sleeptimerDictionary])
		{
			[menuList removeObject: _sleeptimerDictionary];
			reload = YES;
		}
	}

	// Add/Remove Event Search
	/*!
	 @note Full version does emulated epg search in cache, so only check for native
	 search ability in lite version.
	 */
#if IS_FULL()
	if(YES)
#else
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearch])
#endif
	{
		if(![menuList containsObject: _eventSearchDictionary])
		{
			[menuList insertObject: _eventSearchDictionary atIndex: 2];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _eventSearchDictionary])
		{
			[menuList removeObject: _eventSearchDictionary];
			reload = YES;
		}
	}

	// Add/Remove About Receiver
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesAbout])
	{
		if(![menuList containsObject: _aboutDictionary])
		{
			[menuList insertObject: _aboutDictionary atIndex: 0];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _aboutDictionary])
		{
			[menuList removeObject: _aboutDictionary];
			reload = YES;
		}
	}

#if IS_FULL()
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesAutoTimer])
	{
		if(![menuList containsObject:_autotimerDictionary])
		{
			[menuList addObject:_autotimerDictionary]; // add to EOL
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject:_autotimerDictionary])
		{
			[menuList removeObject:_autotimerDictionary];
			reload = YES;
		}
	}
#endif

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesEPGRefresh])
	{
		if(![menuList containsObject:_epgrefreshDictionary])
		{
			[menuList addObject:_epgrefreshDictionary]; // add to EOL
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject:_epgrefreshDictionary])
		{
			[menuList removeObject:_epgrefreshDictionary];
			reload = YES;
		}
	}

	if(reload)
		[myTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	[RemoteConnectorObject cancelPendingOperations];
	[super viewDidAppear:animated];
}

#pragma mark UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [menuList count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if 0
	SEL callfunc = nil;
	[[[menuList objectAtIndex: indexPath.row] objectForKey:@"function"] getValue: &callfunc];
	if(callfunc != nil)
	{
		[[RemoteConnectorObject sharedRemoteConnector] performSelector: callfunc withObject: self.navigationController];
	}
	else
#endif
	{
		UIViewController *targetViewController = [[menuList objectAtIndex: indexPath.row] objectForKey:@"viewController"];
		if([self.navigationController.viewControllers containsObject:targetViewController])
		{
#if IS_DEBUG()
			NSMutableString* result = [[NSMutableString alloc] init];
			for(NSObject* obj in self.navigationController.viewControllers)
				[result appendString:[obj description]];
			[NSException raise:@"OtherListTargetTwiceInNavigationStack" format:@"targetViewController (%@) was twice in navigation stack: %@", [targetViewController description], result];
			 // never reached, but to keep me from going crazy :)
#endif
			[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
		}
		[self.navigationController pushViewController:targetViewController animated:YES];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MainTableViewCell *cell = [MainTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMainCell_ID];

	// set accessory type
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	// get the view controller's info dictionary based on the indexPath's row
	cell.dataDictionary = [menuList objectAtIndex:indexPath.row];

	return cell;
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
