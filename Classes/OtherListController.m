//
//  OtherListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "OtherListController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "MainTableViewCell.h"

#import "AboutViewController.h"
#import "AboutDreamoteViewController.h"
#import "BouquetListController.h"
#import "ConfigViewController.h"
#import "ConfigListController.h"
#import "ControlViewController.h"
#import "CurrentViewController.h"
#import "EventSearchListController.h"
#import "MessageViewController.h"
#import "MovieListController.h"
#import "LocationListController.h"
#import "ServiceListController.h"
#import "SignalViewController.h"
#import "TimerListController.h"
#import "MediaPlayerController.h"

@implementation OtherListController

@synthesize myTableView;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"More", @"Title of OtherListController");
	}
	return self;
}

- (void)dealloc
{
	[myTableView release];
	[menuList release];
	[_eventSearchDictionary release];
	[_mediaPlayerDictionary release];
	[_locationsDictionary release];
	[_recordDictionary release];
	[_signalDictionary release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	if([RemoteConnectorObject isConnected])
		[[RemoteConnectorObject sharedRemoteConnector] freeCaches];

    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
	menuList = [[NSMutableArray alloc] init];

	// create our view controllers - we will encase each title and view controller pair in a NSDictionary
	// and add it to a mutable array.  If you want to add more pages, simply call "addObject" on "menuList"
	// with an additional NSDictionary.  Note we use NSLocalizedString to load a localized version of its title.

	UIViewController *targetViewController;

	targetViewController = [[AboutViewController alloc] init];
	_aboutDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
							 NSLocalizedString(@"About Receiver Title", @""), @"title",
							 NSLocalizedString(@"About Receiver Explain", @""), @"explainText",
							 targetViewController, @"viewController",
							 nil] retain];
	[targetViewController release];

	targetViewController = [[AboutDreamoteViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"About View Title", @""), @"title",
						 NSLocalizedString(@"About View Explain", @""), @"explainText",
						 targetViewController, @"viewController",
						 nil]];
	[targetViewController release];
	
	targetViewController = [[ConfigListController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Config List Title", @""), @"title",
						 NSLocalizedString(@"Config List Explain", @""), @"explainText",
						 targetViewController, @"viewController",
						 nil]];
	[targetViewController release];

	targetViewController = [[EventSearchListController alloc] init];
	_eventSearchDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
							NSLocalizedString(@"Event Search Title", @""), @"title",
							NSLocalizedString(@"Event Search Explain", @""), @"explainText",
							targetViewController, @"viewController",
							nil] retain];
	[targetViewController release];

	targetViewController = [[SignalViewController alloc] init];
	_signalDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
							   NSLocalizedString(@"Signal Title", @""), @"title",
							   NSLocalizedString(@"Signal Explain", @""), @"explainText",
							   targetViewController, @"viewController",
							   nil] retain];
	[targetViewController release];

	if(!IS_IPAD())
	{
		targetViewController = [[LocationListController alloc] init];
		_locationsDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
							NSLocalizedString(@"Location List Title", @""), @"title",
							NSLocalizedString(@"Location List Explain", @""), @"explainText",
							targetViewController, @"viewController",
							nil] retain];
		[targetViewController release];

		targetViewController = [[MovieListController alloc] init];
		_recordDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
							NSLocalizedString(@"Movie List Title", @""), @"title",
							NSLocalizedString(@"Movie List Explain", @""), @"explainText",
							targetViewController, @"viewController",
							nil] retain];
		[targetViewController release];
	}

	targetViewController = [[MediaPlayerController alloc] init];
	_mediaPlayerDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
								   NSLocalizedString(@"Media Player Title", @""), @"title",
								   NSLocalizedString(@"Media Player Explain", @""), @"explainText",
								   targetViewController, @"viewController",
								   nil] retain];
	[targetViewController release];

	targetViewController = [[ControlViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						NSLocalizedString(@"Control View Title", @""), @"title",
						NSLocalizedString(@"Control View Explain", @""), @"explainText",
						targetViewController, @"viewController",
						nil]];
	[targetViewController release];

	targetViewController = [[MessageViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Message View Title", @""), @"title",
						 NSLocalizedString(@"Message View Explain", @""), @"explainText",
						 targetViewController, @"viewController",
						 nil]];
	[targetViewController release];

	myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	if(IS_IPAD())
		myTableView.rowHeight = kUIRowHeight;

	// setup our list view to autoresizing in case we decide to support autorotation along the other UViewControllers
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
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
					[menuList insertObject:_locationsDictionary atIndex: 4];
					reload = YES;
				}
			}
			else
			{
				if(![menuList containsObject: _recordDictionary])
				{
					[menuList removeObject:_locationsDictionary];
					[menuList insertObject:_recordDictionary atIndex: 4];
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
				[menuList insertObject: _mediaPlayerDictionary atIndex: 3];
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
			[menuList insertObject: _signalDictionary atIndex: (IS_IPAD()) ? 4 : 5];
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

	// Add/Remove Event Search
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearch])
	{
		if(![menuList containsObject: _eventSearchDictionary])
		{
			[menuList insertObject: _eventSearchDictionary atIndex: 3];
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
			[menuList insertObject: _aboutDictionary atIndex: 1];
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

	if(reload)
		[myTableView reloadData];
}

#pragma mark UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [menuList count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	SEL callfunc = nil;
	[[[menuList objectAtIndex: indexPath.row] objectForKey:@"function"] getValue: &callfunc];
	if(callfunc != nil)
	{
		[[RemoteConnectorObject sharedRemoteConnector] performSelector: callfunc withObject: self.navigationController];
	}
	else
	{
		UIViewController *targetViewController = [[menuList objectAtIndex: indexPath.row] objectForKey:@"viewController"];
		[self.navigationController pushViewController:targetViewController animated:YES];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MainTableViewCell *cell = (MainTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kMainCell_ID];
	if (cell == nil)
		cell = [[[MainTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMainCell_ID] autorelease];

	// set accessory type
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	// get the view controller's info dictionary based on the indexPath's row
	[cell setDataDictionary: [menuList objectAtIndex:indexPath.row]];

	return cell;
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
