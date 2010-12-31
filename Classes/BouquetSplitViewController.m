    //
//  BouquetSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BouquetSplitViewController.h"


@implementation BouquetSplitViewController

- (id)init
{
    if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
	[_splitViewController release];
	[_bouquetListController release];
	[_serviceListController release];
}

#pragma mark -
#pragma mark UIViewController methods
#pragma mark -

- (void)loadView
{
    [super loadView];

	// Instantiate view controllers
	_bouquetListController = [[BouquetListController alloc] init];
	_bouquetListController.isSplit = YES;
	_serviceListController = [[ServiceListController alloc] init];
	_bouquetListController.serviceListController = _serviceListController;
	_splitViewController = [[UISplitViewController alloc] init];

	// Make service list delegate of split view
	_splitViewController.delegate = _serviceListController;

	// Setup navigation controllers and add to split view
	UIViewController *navController1, *navController2;
	navController1 = [[UINavigationController alloc] initWithRootViewController: _bouquetListController];
	navController2 = [[UINavigationController alloc] initWithRootViewController: _serviceListController];
	_splitViewController.viewControllers = [NSArray arrayWithObjects: navController1, navController2, nil];
	[navController1 release];
	[navController2 release];

	// Link view to us
	self.view = _splitViewController.view;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[_splitViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[_splitViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)viewWillAppear: (BOOL)animated
{
	[super viewWillAppear: animated];
	[_splitViewController viewWillAppear: animated];
}

- (void)viewDidAppear: (BOOL)animated
{
	[super viewDidAppear: animated];
	[_splitViewController viewDidAppear: animated];
}

- (void)viewWillDisppear: (BOOL)animated
{
	[super viewWillDisappear: animated];
	[_splitViewController viewWillDisappear: animated];
}

- (void)viewDidDisappear: (BOOL)animated
{
	[super viewDidDisappear: animated];
	[_splitViewController viewDidDisappear: animated];
}

@end
