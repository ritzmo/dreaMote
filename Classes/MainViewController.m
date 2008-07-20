//
//  MainViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

#import "MyCustomCell.h"
#import "ServiceListController.h"
#import "TimerListController.h"
#import "ControlViewController.h"

//#include "AppDelegateMethods.h"

@implementation MainViewController

static NSString *kMainCell_ID = @"MainCell_ID";

@synthesize myTableView;

- (id)init
{
	if (self = [super init])
	{
		// make the title of this page the same as the title of this app
		self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	}
	return self;
}

- (void)dealloc
{
    [myTableView release];
	[menuList release];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	menuList = [[NSMutableArray alloc] init];

	// setup the parent content view to host the UITableView
	UIView *contentView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[contentView setBackgroundColor:[UIColor blackColor]];
	self.view = contentView;
	[contentView release];
	
	// setup our content view so that it auto-rotates along with the UViewController
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	// create our view controllers - we will encase each title and view controller pair in a NSDictionary
	// and add it to a mutable array.  If you want to add more pages, simply call "addObject" on "menuList"
	// with an additional NSDictionary.  Note we use NSLocalizedString to load a localized version of its title.
	
	ServiceListController *serviceListController = [[ServiceListController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												NSLocalizedString(@"Service List Title", @""), @"title",
												NSLocalizedString(@"Service List Explain", @""), @"explainText",
												serviceListController, @"viewController",
												nil]];
	[serviceListController release];
	
	TimerListController *timerListController = [[TimerListController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												NSLocalizedString(@"Timer List Title", @""), @"title",
												NSLocalizedString(@"Timer List Explain", @""), @"explainText",
												timerListController, @"viewController",
												nil]];

	[timerListController release];

	ControlViewController *controlViewController = [[ControlViewController alloc] init];
	[menuList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												NSLocalizedString(@"Control View Title", @""), @"title",
												NSLocalizedString(@"Control View Explain", @""), @"explainText",
												controlViewController, @"viewController",
												nil]];

	[controlViewController release];

	UINavigationItem *navItem = self.navigationItem;
	
	// Add the "Settings" button to the navigation bar
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"") style: UIBarButtonItemStyleDone
														target:self action:@selector(settingsAction:)];
	navItem.leftBarButtonItem = button;
	
	// finally create a our table, its contents will be populated by "menuList" using the UITableView delegate methods
	myTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
	// setup our list view to autoresizing in case we decide to support autorotation along the other UViewControllers
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	[myTableView reloadData];	// populate our table's data
	//[self.view addSubview: myTableView];
	self.view = myTableView;
}

- (void)settingsAction:(id)sender
{
	// TODO: open settings dialogue
}

#pragma mark UIViewController delegates

- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [myTableView indexPathForSelectedRow];
	[myTableView deselectRowAtIndexPath:tableSelection animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
	// do something here as our view re-appears
}


#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

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
	[[self navigationController] pushViewController:targetViewController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MyCustomCell *cell = (MyCustomCell*)[tableView dequeueReusableCellWithIdentifier:kMainCell_ID];
    if (cell == nil)
    {
        cell = [[[MyCustomCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMainCell_ID] autorelease];
    }
	
	// get the view controller's info dictionary based on the indexPath's row
	[cell setDataDictionary: [menuList objectAtIndex:indexPath.row]];
	
	return cell;
}

@end
