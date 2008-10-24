//
//  MainViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "MainTableViewCell.h"
#import "ServiceListController.h"
#import "TimerListController.h"
#import "ControlViewController.h"
#import "RCEmulatorController.h"
#import "MovieListController.h"
#import "ConfigViewController.h"
#import "ConfigListController.h"
#import "MessageViewController.h"
#import "AboutViewController.h"

@implementation MainViewController

@synthesize myTableView;

- (id)init
{
	if (self = [super init])
	{
		// make the title of this page the same as the title of this app
		self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
		configListController = nil;
		_recordDictionary = nil;
	}
	return self;
}

- (void)dealloc
{
	[myTableView release];
	[menuList release];
	[configListController release];
	[aboutViewController release];
	[_recordDictionary release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[configListController release];
	configListController = nil;
	[aboutViewController release];
	aboutViewController = nil;

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

	targetViewController = [[ServiceListController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												NSLocalizedString(@"Service List Title", @""), @"title",
												NSLocalizedString(@"Service List Explain", @""), @"explainText",
												targetViewController, @"viewController",
												nil]];
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

	targetViewController = [[RCEmulatorController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 NSLocalizedString(@"Remote Control Title", @""), @"title",
						 NSLocalizedString(@"Remote Control Explain", @""), @"explainText",
						 targetViewController, @"viewController",
						 nil]];
	
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

	// Add the "Settings" button to the navigation bar
	UIBarButtonItem *button = [[UIBarButtonItem alloc]
											initWithTitle: NSLocalizedString(@"Settings", @"")
											style: UIBarButtonItemStyleDone
											target: self action: @selector(settingsAction:)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];

	// Add the "About" button to the navigation bar
	UIButton* aboutViewButton = [UIButton buttonWithType: UIButtonTypeInfoLight];
	[aboutViewButton addTarget:self action:@selector(aboutAction:) forControlEvents:UIControlEventTouchUpInside];
	button = [[UIBarButtonItem alloc] initWithCustomView: aboutViewButton];
	self.navigationItem.leftBarButtonItem = button;
	[aboutViewButton release];
	[button release];

	// finally create a our table, its contents will be populated by "menuList" using the UITableView delegate methods
	myTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	myTableView.scrollEnabled = NO;

	// setup our list view to autoresizing in case we decide to support autorotation along the other UViewControllers
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = myTableView;
	[myTableView release];
}

- (void)settingsAction:(id)sender
{
	if(configListController == nil)
		configListController = [[ConfigListController alloc] init];
	[self.navigationController pushViewController: configListController animated: YES];
}

- (void)aboutAction: (id)sender
{
	if(aboutViewController == nil)
		aboutViewController = [[AboutViewController alloc] init];
	[self.navigationController presentModalViewController: aboutViewController animated:YES];
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:NO];

	id connId = [[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection];
	if(![RemoteConnectorObject isConnected])
		if(![RemoteConnectorObject connectTo: [connId integerValue]])
			return;

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordInfo])
	{
		if(![menuList containsObject: _recordDictionary])
		{
			[menuList insertObject:_recordDictionary atIndex: 2];
			[myTableView reloadData];
		}
	}
	else
	{
		if([menuList containsObject: _recordDictionary])
		{
			[menuList removeObject: _recordDictionary];
			[myTableView reloadData];
		}
	}
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

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIViewController *targetViewController = [[menuList objectAtIndex: indexPath.row] objectForKey:@"viewController"];
	[self.navigationController pushViewController:targetViewController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MainTableViewCell *cell = (MainTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kMainCell_ID];
	if (cell == nil)
		cell = [[[MainTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMainCell_ID] autorelease];

	// get the view controller's info dictionary based on the indexPath's row
	[cell setDataDictionary: [menuList objectAtIndex:indexPath.row]];

	return cell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
