//
//  OtherSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 06.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "OtherSplitViewController.h"

#import <ListController/OtherListController.h>
#import <ViewController/ConfigViewController.h>

@implementation OtherSplitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
		self.tabBarItem.title = NSLocalizedString(@"More", @"Tab Title of OtherListController");
		self.showsMasterInPortrait = YES;
	}
	return self;
}

#pragma mark - View lifecycle

- (void)loadView
{
	[super loadView];
#if IS_DEBUG()
	NSLog(@"[OtherSplitViewController] loadView");
#endif

	if(!isInit)
	{
		isInit = YES;

		// Instantiate view controllers
		OtherListController *olc = [[OtherListController alloc] init];
		olc.mgSplitViewController = self;
		AboutDreamoteViewController *vc = [[AboutDreamoteViewController alloc] initWithWelcomeType:welcomeTypeFull];
		vc.aboutDelegate = self;

		// Setup navigation controllers and add to split view
		UIViewController *navController1, *navController2;
		navController1 = [[UINavigationController alloc] initWithRootViewController:olc];
		navController2 = [[UINavigationController alloc] initWithRootViewController:vc];
		self.viewControllers = [NSArray arrayWithObjects: navController1, navController2, nil];
	}
}

#pragma mark - AboutDreamoteDelegate

- (void)dismissedAboutDialog
{
	// ignore? should never happen :)
}

- (BOOL)shouldShowDoneButton
{
	return NO;
}

#pragma mark - OtherViewProtocol

- (void)forceConfigDialog
{
	UIViewController *detailViewController = self.detailViewController;
	// TODO: select settings item?
	if([detailViewController isKindOfClass:[UINavigationController class]]
	   && [((UINavigationController *)detailViewController).visibleViewController isKindOfClass:[ConfigViewController class]])
	{
		((ConfigViewController *)((UINavigationController *)detailViewController).visibleViewController).mustSave = YES;
	}
	else
	{
		ConfigViewController *targetViewController = [ConfigViewController newConnection];
		targetViewController.mustSave = YES;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:targetViewController];
		self.detailViewController = navController;
	}
}

@end
