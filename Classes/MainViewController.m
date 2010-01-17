//
//  MainViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
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

@interface MainViewController()
/*!
 @brief open settings dialog
 @param sender ui element
 */
- (void)settingsAction:(id)sender;
/*!
 @brief display about dialog
 @param sender ui element
 */
- (void)aboutAction: (id)sender;
@end

@implementation MainViewController

@synthesize myTableView;

- (id)init
{
	if((self = [super init]))
	{
		// make the title of this page the same as the title of this app
		self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
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
	[_aboutViewController release];
	[_bouquetDictionary release];
	[_currentDictionary release];
	[_eventSearchDictionary release];
	[_recordDictionary release];
	[_serviceDictionary release];
	[_signalDictionary release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[_configListController release];
	_configListController = nil;
	[_aboutViewController release];
	_aboutViewController = nil;

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

	UIViewController *targetViewController;

	targetViewController = [[CurrentViewController alloc] init];
	_currentDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						   NSLocalizedString(@"Currently playing List Title", @""), @"title",
						   NSLocalizedString(@"Currentply playing List Explain", @""), @"explainText",
						   targetViewController, @"viewController",
						   nil] retain];
	[targetViewController release];

	targetViewController = [[BouquetListController alloc] init];
	_bouquetDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						NSLocalizedString(@"Bouquet List Title", @""), @"title",
						NSLocalizedString(@"Bouquet List Explain", @""), @"explainText",
						targetViewController, @"viewController",
						nil] retain];
	[targetViewController release];

	targetViewController = [[ServiceListController alloc] init];
	_serviceDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						NSLocalizedString(@"Service List Title", @""), @"title",
						NSLocalizedString(@"Service List Explain", @""), @"explainText",
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

	targetViewController = [[TimerListController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						NSLocalizedString(@"Timer List Title", @""), @"title",
						NSLocalizedString(@"Timer List Explain", @""), @"explainText",
						targetViewController, @"viewController",
						nil]];

	[targetViewController release];

	targetViewController = [[MovieListController alloc] init];
	_recordDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Movie List Title", @""), @"title",
						 NSLocalizedString(@"Movie List Explain", @""), @"explainText",
						 targetViewController, @"viewController",
						 nil] retain];

	[targetViewController release];

	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Remote Control Title", @""), @"title",
						 NSLocalizedString(@"Remote Control Explain", @""), @"explainText",
						 [NSValue valueWithBytes: &@selector(openRCEmulator:) objCType:@encode(SEL)], @"function",
						 nil]];

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

	// Add the "Settings" button to the navigation bar
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(0.0, 0.0, 22.0, 22.0)];
	UIImage *image = [UIImage imageNamed:@"preferences-system.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(settingsAction:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView: button];
	self.navigationItem.rightBarButtonItem = buttonItem;
	[button release];
	[buttonItem release];

	// Add the "About" button to the navigation bar
	button = [UIButton buttonWithType: UIButtonTypeInfoLight];
	[button addTarget:self action:@selector(aboutAction:) forControlEvents:UIControlEventTouchUpInside];
	buttonItem = [[UIBarButtonItem alloc] initWithCustomView: button];
	self.navigationItem.leftBarButtonItem = buttonItem;
	[button release];
	[buttonItem release];

	// finally create a our table, its contents will be populated by "menuList" using the UITableView delegate methods
	myTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// setup our list view to autoresizing in case we decide to support autorotation along the other UViewControllers
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = myTableView;
	[myTableView release];
}

- (void)settingsAction:(id)sender
{
	if(_configListController == nil)
		_configListController = [[ConfigListController alloc] init];
	[self.navigationController pushViewController: _configListController animated: YES];
}

- (void)aboutAction: (id)sender
{
	if(_aboutViewController == nil)
		_aboutViewController = [[AboutViewController alloc] init];
	[self.navigationController presentModalViewController: _aboutViewController animated:YES];
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:NO];

	const id connId = [[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection];
	if(![RemoteConnectorObject isConnected])
		if(![RemoteConnectorObject connectTo: [connId integerValue]])
			return;

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

	// Handle Single-Bouquet mode
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
		&& (
			[RemoteConnectorObject isSingleBouquet] ||
			![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets])
		)
	{
		if(![menuList containsObject: _serviceDictionary])
		{
			[menuList removeObject: _bouquetDictionary];
			[menuList insertObject: _serviceDictionary atIndex: 0];
			reload = YES;
		}
	}
	else
	{
		if(![menuList containsObject: _bouquetDictionary])
		{
			[menuList removeObject: _serviceDictionary];
			[menuList insertObject: _bouquetDictionary atIndex: 0];
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
	
	// Add/Remove currently playing
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCurrent])
	{
		if(![menuList containsObject: _currentDictionary])
		{
			[menuList insertObject: _currentDictionary atIndex: 0];
			reload = YES;
		}
	}
	else
	{
		if([menuList containsObject: _currentDictionary])
		{
			[menuList removeObject: _currentDictionary];
			reload = YES;
		}
	}

	if(reload)
		[myTableView reloadData];
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
		[notification show];
		[notification release];

		UIViewController *targetViewController = [ConfigViewController newConnection];
		[self.navigationController pushViewController: targetViewController animated: YES];
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

		[self settingsAction: nil];
	}
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
