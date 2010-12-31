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

- (void)loadView
{
    [super loadView];

	// Instantiate view controllers
	_bouquetListController = [[BouquetListController alloc] init];
	_bouquetListController.isSplit = YES;
	_serviceListController = [[ServiceListController alloc] init];
	_bouquetListController.serviceListController = _serviceListController;
	_splitViewController = [[UISplitViewController alloc] init];

	// Setup navigation controllers and add to split view
	UIViewController *navController1, *navController2;
	navController1 = [[UINavigationController alloc] initWithRootViewController: _bouquetListController];
	navController2 = [[UINavigationController alloc] initWithRootViewController: _serviceListController];
	_splitViewController.viewControllers = [NSArray arrayWithObjects: navController1, navController2, nil];
	[navController1 release];
	[navController2 release];

	// Make service list delegate of split view
	_splitViewController.delegate = _serviceListController;
	
	// Link view to us
	self.view = _splitViewController.view;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillAppear: (BOOL)animated
{
	[super viewWillAppear: animated];
	[_bouquetListController viewWillAppear: YES];
	[_serviceListController viewWillAppear: YES];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	[_splitViewController release];
	[_bouquetListController release];
	[_serviceListController release];
}


@end
