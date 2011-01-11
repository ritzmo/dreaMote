//
//  TimerSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010-2011 Moritz Venn. All rights reserved.
//

#import "TimerSplitViewController.h"

@implementation TimerSplitViewController

- (id)init
{
    if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Timers", @"Title of TimerListController");
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
	[_timerListController release];
	[_timerViewController release];
}

#pragma mark -
#pragma mark UIViewController methods
#pragma mark -

- (void)loadView
{
    [super loadView];

	// Instantiate view controllers
	_timerListController = [[TimerListController alloc] init];
	_timerListController.isSplit = YES;
	_timerViewController = [TimerViewController newTimer];
	_timerListController.timerViewController = _timerViewController;

	// Make timer view delegate of split view
	self.delegate = _timerViewController;

	// Setup navigation controllers and add to split view
	UIViewController *navController1, *navController2;
	navController1 = [[UINavigationController alloc] initWithRootViewController: _timerListController];
	navController2 = [[UINavigationController alloc] initWithRootViewController: _timerViewController];
	self.viewControllers = [NSArray arrayWithObjects: navController1, navController2, nil];
	[navController1 release];
	[navController2 release];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	// tell timer list that it will reappear, that way we don't have to reload every two rotations.
	_timerListController.willReappear = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

@end
