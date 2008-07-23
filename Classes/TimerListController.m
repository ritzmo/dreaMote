//
//  TimerListController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerListController.h"

#import "TimerTableViewCell.h"
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
	[tableView reloadData];

	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
														target:self action:@selector(addAction:)];
	UINavigationItem *navItem = self.navigationItem;
	navItem.rightBarButtonItem = addButton;

	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	// Spawn a thread to fetch the timer data so that the UI is not blocked while the 
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchTimers) toTarget:self withObject:nil];

	[super viewWillAppear: animated];
}

- (void)fetchTimers
{
	[_timers removeAllObjects];

	dist[0] = 0;
	dist[1] = 0;
	dist[2] = 0;
	dist[3] = 0;

	[self reloadData];

	[[RemoteConnectorObject sharedRemoteConnector] fetchTimers:self action:@selector(addTimer:)];
}

- (void)addTimer:(id)newTimer
{
	if(newTimer == nil)
		[self reloadData];
	else
	{
		Timer* timer = [(Timer*)newTimer retain];

		int state = [timer state];

		int i;
		for(i = 3; i > state; i--){
			dist[i]++;
		}

		[_timers insertObject:timer atIndex:dist[state]++];
		
		if(!(dist[3] % 10))
			[self reloadData];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kTimerCell_ID = @"TimerCell_ID";

	TimerTableViewCell *cell = (TimerTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kTimerCell_ID];
	if(cell == nil)
	{
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[TimerTableViewCell alloc] initWithFrame:cellFrame reuseIdentifier:kTimerCell_ID] autorelease];
	}

	// XXX: I really should think about the way i keep track of items in a section
	int offset = 0;
	if(indexPath.section > 0)
		offset = dist[indexPath.section-1];
	[cell setTimer: [[self timers] objectAtIndex: offset + indexPath.row]];

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
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Timer Action Title", @"")
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Edit", @""), NSLocalizedString(@"Delete", @""), nil];
	[actionSheet showInView:self.view];
	[actionSheet release];

	return indexPath; // nil to disable select
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		// Second Button: Edit
		id applicationDelegate = [[UIApplication sharedApplication] delegate];

		Timer *timer = [(TimerTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] timer];

		if([timer state] != 0)
		{
			UIAlertView *notification = [[UIAlertView alloc] initWithTitle:@"Error:" message:@"Can't edit a running or finished timer." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[notification show];
			[notification release];
		}
		else
		{
			TimerViewController *timerViewController = [TimerViewController withTimer: timer];
			[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

			//[timerViewController release];
		}
	}
	else if (buttonIndex == 1)
	{
		// Third Button: Delete
		// XXX: I'd actually add another dialogue to confirm the removal of this timer but that would require another modalView as far as I understand ;-) 
		Timer *timer = [(TimerTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] timer];

		if([[RemoteConnectorObject sharedRemoteConnector] delTimer: timer])
		{
			dist[[timer state]]--;
			[_timers removeObject: timer];
			[self reloadData];
		}
	}

	NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
	[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return NSLocalizedString(@"Waiting", @"");
	else if(section == 1)
		return NSLocalizedString(@"Prepared", @"");
	else if (section == 2)
		return NSLocalizedString(@"Running", @"");
	else
		return NSLocalizedString(@"Finished", @"");
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(section > 0)
		return dist[section] - dist[section-1];
	return dist[0];
}

@end
