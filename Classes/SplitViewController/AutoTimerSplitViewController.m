//
//  AutoTimerSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 06.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerSplitViewController.h"

#import <ListController/AutoTimerListController.h>
#import <ViewController/AutoTimerViewController.h>

@implementation AutoTimerSplitViewController

#pragma mark - View lifecycle

- (void)loadView
{
	[super loadView];

	AutoTimerListController *lc = [[AutoTimerListController alloc] init];
	AutoTimerViewController *vc = [AutoTimerViewController newAutoTimer];
	lc.isSplit = YES;
	lc.autotimerView = vc;

	// Setup navigation controllers and add to split view
	UIViewController *navController;
	navController = [[UINavigationController alloc] initWithRootViewController:vc];
	self.viewControllers = [NSArray arrayWithObjects: lc, navController, nil];
}

@end
