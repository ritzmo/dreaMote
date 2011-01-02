//
//  MovieSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 02.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MovieSplitViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

@interface MovieSplitViewController()
- (void)linkViewControllers: (NSNotification *)note;
@end

@implementation MovieSplitViewController

- (id)init
{
    if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Recordings", @"Title of MovieSplitViewController");
    }
    return self;
}

- (void)dealloc
{
	[_locationListController release];
	[_movieListController release];
	[_movieViewController release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

#pragma mark -
#pragma mark UIViewController methods
#pragma mark -

- (void)loadView
{
    [super loadView];

	// Instantiate view controllers
	_locationListController = [[LocationListController alloc] init];
	_locationListController.isSplit = YES;
	_movieListController = [[MovieListController alloc] init];
	_movieViewController = [[MovieViewController alloc] init];

	// Build connection
	_locationListController.movieListController = _movieListController;
	_movieListController.movieViewController = _movieViewController;

	[self linkViewControllers: nil];

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(linkViewControllers:) name:kReconnectNotification object:nil];
}

- (void)linkViewControllers: (NSNotification *)note
{
	// Setup navigation controllers and add to split view
	UIViewController *navController1, *navController2;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
	{
		navController1 = [[UINavigationController alloc] initWithRootViewController: _locationListController];
		navController2 = [[UINavigationController alloc] initWithRootViewController: _movieListController];
		_movieListController.isSplit = NO;
		self.delegate = _movieListController;
	}
	else
	{
		navController1 = [[UINavigationController alloc] initWithRootViewController: _movieListController];
		navController2 = [[UINavigationController alloc] initWithRootViewController: _movieViewController];
		_movieListController.currentLocation = nil;
		_movieListController.isSplit = YES;
		self.delegate = _movieViewController;
	}
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
