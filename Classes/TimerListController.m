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
	tableView.rowHeight = 62.0;
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
	[(UITableView *)self.view reloadData];

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

	//[timerViewController release];
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Timer Action Title", @"") message:NSLocalizedString(@"Timer Action Message", @"")
									delegate:self defaultButton:nil cancelButton:NSLocalizedString(@"Cancel", @"") otherButtons:NSLocalizedString(@"Edit", @""), NSLocalizedString(@"Delete", @""), nil];
	[actionSheet showInView:self.view];
	[actionSheet release];

	return indexPath; // nil to disable select
}

- (void)modalView:(UIModalView *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		// Second Button: Edit
		id applicationDelegate = [[UIApplication sharedApplication] delegate];

		Timer *timer = [(TimerTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] timer];
		TimerViewController *timerViewController = [TimerViewController withTimer: timer];
		[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

		//[timerViewController release];
	}
	else if (buttonIndex == 2)
	{
		// Third Button: Delete
		// XXX: add delete ;-)
	}

	NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
	[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:NO];
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
