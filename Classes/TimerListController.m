//
//  TimerListController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerListController.h"

#import "TimerTableViewCell.h"
#import "AppDelegateMethods.h"
#import "RemoteConnectorObject.h"
#import "Timer.h"
#import "TimerViewController.h"

@implementation TimerListController

@synthesize timers = _timers;

- (id)init
{
    self = [super init];
    if (self) {
		self.timers = [NSMutableArray array];
        self.title = NSLocalizedString(@"Timers", @"");
    }
    return self;
}

- (void)dealloc
{
	[_timers release];

	[super dealloc];
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
    tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 48.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// add our custom add button as the nav bar's custom right view
	UIButton *addButton = [UIButton buttonWithType:UIButtonTypeNavigation];
	[addButton setImage:[UIImage imageNamed:@"addicon.png"] forStates:UIControlStateNormal];
	[addButton addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
	UINavigationItem *navItem = self.navigationItem;
	navItem.customRightView = addButton;

	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_timers release];
	_timers = [[[RemoteConnectorObject sharedRemoteConnector] fetchTimers] retain];

	[super viewWillAppear: animated];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath withAvailableCell:(UITableViewCell *)availableCell {
	TimerTableViewCell *cell = nil;
	if (availableCell != nil) {
		cell = (TimerTableViewCell *)availableCell;
	} else {
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[TimerTableViewCell alloc] initWithFrame:cellFrame] autorelease];
	}

	cell.timer = [[self timers] objectAtIndex:indexPath.row];

	return cell;
}

- (void)addAction:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	TimerViewController *timerViewController = [TimerViewController newTimer];
	[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

	[timerViewController release];
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Timer Action Title", @"") message:NSLocalizedString(@"Timer Action Message", @"")
									delegate:self defaultButton:nil cancelButton:nil otherButtons:@"Edit", @"Delete", nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
	
	return indexPath; // nil to disable select

}

- (void)modalView:(UIModalView *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the user clicked one of our buttons
	if (buttonIndex == 0)
	{
		id applicationDelegate = [[UIApplication sharedApplication] delegate];

		Timer *timer = [(TimerTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] timer];
		TimerViewController *timerViewController = [TimerViewController withTimer: timer];
		[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

		[timerViewController release];
	}
	else
	{
		// XXX: add delete ;-)
	}

	NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
	[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:NO];
}

- (void)tableView:(UITableView *)tableView selectionDidChangeToIndexPath:(NSIndexPath *)newIndexPath fromIndexPath:(NSIndexPath *)oldIndexPath
{
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	// TODO: handle seperators?
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [[self timers] count];
}

@end
