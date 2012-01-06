//
//  TimerSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010-2011 Moritz Venn. All rights reserved.
//

#import "TimerSplitViewController.h"

#import "Constants.h"

#import "Objects/Generic/Timer.h"

@interface TimerSplitViewController()
- (void)reinitializeTimerView:(NSNotification *)notif;
@end


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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIViewController methods
#pragma mark -

- (void)loadView
{
    [super loadView];

	// Instantiate view controllers
	_timerListController = [[TimerListController alloc] init];
	_timerListController.mgSplitViewController = self;
	_timerViewController = [TimerViewController newTimer];
	_timerViewController.delegate = _timerListController;
	_timerListController.timerViewController = _timerViewController;

	// Make timer view delegate of split view
	self.delegate = _timerViewController;

	// Setup navigation controllers and add to split view
	UIViewController *navController1, *navController2;
	navController1 = [[UINavigationController alloc] initWithRootViewController: _timerListController];
	navController2 = [[UINavigationController alloc] initWithRootViewController: _timerViewController];
	self.viewControllers = [NSArray arrayWithObjects: navController1, navController2, nil];

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reinitializeTimerView:) name:kReconnectNotification object:nil];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if(_timerListController.mgSplitViewController == self)
		_timerListController.mgSplitViewController = nil;
	_timerListController.timerViewController = nil;
	if(_timerViewController.delegate == _timerListController)
		_timerViewController.delegate = nil;
	_timerListController = nil;
	_timerViewController = nil;

	[super viewDidUnload];
}

- (void)reinitializeTimerView:(NSNotification *)notif
{
	// so we don't accidentally have auto here if we don't support it…
	// disables top secret timer-transfer capability though :-D
	_timerViewController.timer = [GenericTimer timer];
	_timerViewController.creatingNewTimer = YES;
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
