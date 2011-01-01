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

- (void)dealloc
{
    [super dealloc];
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

	// Make service list delegate of split view
	self.delegate = _serviceListController;

	// Setup navigation controllers and add to split view
	UIViewController *navController1, *navController2;
	navController1 = [[UINavigationController alloc] initWithRootViewController: _bouquetListController];
	navController2 = [[UINavigationController alloc] initWithRootViewController: _serviceListController];
	self.viewControllers = [NSArray arrayWithObjects: navController1, navController2, nil];
	[navController1 release];
	[navController2 release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

@end
