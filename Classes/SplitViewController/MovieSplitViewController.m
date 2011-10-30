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

		UIImage *image = [UIImage imageNamed: @"movie.png"];
		self.tabBarItem.image = image;
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	// force fetch of location list else we might run into a timeout
	//[_locationListController forceRefresh];
	_movieListController = [[MovieListController alloc] init];

	// Build Navigation arrays
	UIViewController *navController;
	navController = [[UINavigationController alloc] initWithRootViewController: _locationListController];
	_movieListNavigationController = [[UINavigationController alloc] initWithRootViewController: _movieListController];
	_viewArrayLocation = [NSArray arrayWithObjects: navController, _movieListNavigationController, nil];

	// Build connection
	_locationListController.movieListController = _movieListController;

	[self linkViewControllers: nil];

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(linkViewControllers:) name:kReconnectNotification object:nil];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	SafeRetainAssign(_locationListController, nil);
	SafeRetainAssign(_movieListController, nil);
	SafeRetainAssign(_movieListNavigationController, nil);

	SafeRetainAssign(_viewArrayLocation, nil);

	[super viewDidUnload];
}

- (void)linkViewControllers: (NSNotification *)note
{
	NSArray *newViewControllers = nil;

	// Reset current location
	_movieListController.currentLocation = nil;

	// Do we have location support?
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
	{
		_movieListController.movieViewController = nil;
		_movieListController.isSplit = NO;
		self.delegate = _movieListController;
		newViewControllers = _viewArrayLocation;
	}
	// Use "regular" view controllers
	else
	{
		MovieViewController *viewController = [[MovieViewController alloc] init];
		UIViewController *navController = [[UINavigationController alloc] initWithRootViewController: viewController];
		[_movieListNavigationController popToRootViewControllerAnimated: NO];
		_movieListController.navigationItem.leftBarButtonItem = nil; // FIXME: GAAAAAH!
		_movieListController.movieViewController = viewController;
		_movieListController.isSplit = YES;
		self.delegate = viewController;
		newViewControllers = [NSArray arrayWithObjects: _movieListNavigationController, navController, nil];
	}
	self.viewControllers = newViewControllers;

	// pretend to rotate, or the master might be hidden
	[self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0.0];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	// tell master that it will reapper
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
		_locationListController.willReappear = YES;
	else
		_movieListController.willReappear = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

@end
