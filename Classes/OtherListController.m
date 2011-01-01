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

@interface OtherListController()
/*!
 @brief open settings dialog
 @param sender ui element
 */
- (void)settingsAction:(id)sender;
@end

@implementation OtherListController

@synthesize myTableView;

- (id)init
{
	if((self = [super init]))
	{
		// make the title of this page the same as the title of this app
		self.title = NSLocalizedString(@"Other", @"Title of OtherListController");
		_configListController = nil;
		_aboutViewController = nil;
	}
	return self;
}

- (void)dealloc
{
	[myTableView release];
	[menuList release];
	[_configListController release];
	[_eventSearchDictionary release];
	[_recordDictionary release];
	[_signalDictionary release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[_configListController release];
	_configListController = nil;

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

	targetViewController = [[BouquetListController alloc] init];
	((BouquetListController *)targetViewController).isRadio = YES;
	_radioBouquetDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						   NSLocalizedString(@"Radio Bouquet List Title", @""), @"title",
						   NSLocalizedString(@"Radio Bouquet List Explain", @""), @"explainText",
						   targetViewController, @"viewController",
						   nil] retain];
	[targetViewController release];

	targetViewController = [[ServiceListController alloc] init];
	((ServiceListController *)targetViewController).isRadio = YES;
	_radioServiceDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						   NSLocalizedString(@"Radio Service List Title", @""), @"title",
						   NSLocalizedString(@"Radio Service List Explain", @""), @"explainText",
						   targetViewController, @"viewController",
						   nil] retain];
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

	targetViewController = [[MovieListController alloc] init];
	_recordDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Movie List Title", @""), @"title",
						 NSLocalizedString(@"Movie List Explain", @""), @"explainText",
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

	targetViewController = [[AboutViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"About View Title", @""), @"title",
						 NSLocalizedString(@"About View Explain", @""), @"explainText",
						 targetViewController, @"viewController",
						 nil]];
	[targetViewController release];

	// Add the "Settings" button to the navigation bar
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 22, 22)];
	UIImage *image = [UIImage imageNamed:@"preferences-system.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(settingsAction:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView: button];
	self.navigationItem.rightBarButtonItem = buttonItem;
	[button release];
	[buttonItem release];

	myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	if(IS_IPAD())
		myTableView.rowHeight = kUIRowHeight;

	// setup our list view to autoresizing in case we decide to support autorotation along the other UViewControllers
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
}

- (void)settingsAction:(id)sender
{
	if(_configListController == nil)
		_configListController = [[ConfigListController alloc] init];
	[self.navigationController pushViewController: _configListController animated: YES];
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
	const BOOL isSingleBouquet =
		[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
		&& (
			[RemoteConnectorObject isSingleBouquet] ||
			![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets]);
	BOOL reload = NO;
	/* The menu reorganization might be buggy, this should be redone
	   as it was a bad hack to begin with */
	// Add/Remove Record
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordInfo])
	{
		if(![menuList containsObject: _recordDictionary])
		{
			[menuList insertObject:_recordDictionary atIndex: 2];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _recordDictionary])
		{
			[menuList removeObject: _recordDictionary];
			reload = YES;
		}
	}

	// Add/Remove Signal Finder
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearch])
	{
		if(![menuList containsObject: _signalDictionary])
		{
			[menuList insertObject: _signalDictionary atIndex: 3];
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
			[menuList insertObject: _eventSearchDictionary atIndex: 1];
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
