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
#import "TimerViewController.h"

#import "Constants.h"

@implementation TimerListController

@synthesize timers = _timers;

- (id)init
{
	self = [super init];
	if (self) {
		self.timers = [NSMutableArray array];
		self.title = NSLocalizedString(@"Timers", @"Title of TimerListController");
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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 62.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	[tableView reloadData];

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	[super setEditing: editing animated: animated];
	[(UITableView*)self.view setEditing: editing animated: animated];

	if(editing)
	{
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
	{
		[(UITableView*)self.view deleteRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
						withRowAnimation: UITableViewRowAnimationFade];
	}

	[self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSInteger i;
	for(i = 0; i < kTimerStateMax; i++)
		dist[i] = 0;
	
	[_timers removeAllObjects];
	
	[self reloadData];

	// Spawn a thread to fetch the timer data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchTimers) toTarget:self withObject:nil];

	[super viewWillAppear: animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	NSInteger i;
	for(i = 0; i < kTimerStateMax; i++)
		dist[i] = 0;

	[_timers removeAllObjects];

	[self reloadData];
}

- (void)fetchTimers
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[RemoteConnectorObject sharedRemoteConnector] fetchTimers:self action:@selector(addTimer:)];
	[pool release];
}

- (void)addTimer:(id)newTimer
{
	if(newTimer != nil)
	{
		Timer* timer = (Timer*)newTimer;

		NSInteger state = timer.state;

		[_timers insertObject:timer atIndex:dist[state]];

		for(; state <= 3; state++){
			dist[state]++;
		}
	}
	[self reloadData];
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";
	static NSString *kTimerCell_ID = @"TimerCell_ID";

	NSInteger section = indexPath.section;
	UITableViewCell *cell = nil;

	if(section == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
		if(cell == nil)
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

		cell.text = NSLocalizedString(@"New Timer", @"");
		cell.font = [UIFont systemFontOfSize:kTextViewFontSize]; // XXX: Looks a little weird though

		return cell;
	}
	--section;
	
	cell = [tableView dequeueReusableCellWithIdentifier:kTimerCell_ID];
	if(cell == nil)
		cell = [[[TimerTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kTimerCell_ID] autorelease];

	NSInteger offset = 0;
	if(section > 0)
		offset = dist[section-1];
	((TimerTableViewCell *)cell).timer = [_timers objectAtIndex: offset + indexPath.row];

	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	NSInteger index = indexPath.row;
	if(indexPath.section > 0)
		index += dist[indexPath.section-1];

	Timer *timer = [_timers objectAtIndex: index];

	TimerViewController *timerViewController = [TimerViewController withTimer: timer];
	[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return kTimerStateMax + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return nil;
	--section;

	if(section == kTimerStateWaiting)
		return NSLocalizedString(@"Waiting", @"");
	else if(section == kTimerStatePrepared)
		return NSLocalizedString(@"Prepared", @"");
	else if (section == kTimerStateRunning)
		return NSLocalizedString(@"Running", @"");
	else
		return NSLocalizedString(@"Finished", @"");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(self.editing && section == 0)
		return 1;
	--section;

	if(section > 0)
		return dist[section] - dist[section-1];
	return dist[0];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		Timer *timer = ((TimerTableViewCell *)[tableView cellForRowAtIndexPath: indexPath]).timer;
		if([[RemoteConnectorObject sharedRemoteConnector] delTimer: timer])
		{
			[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
							 withRowAnimation: UITableViewRowAnimationFade];

			[_timers removeObject: timer];
		}
		else
		{
			// Alert otherwise
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:nil
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		id applicationDelegate = [[UIApplication sharedApplication] delegate];

		TimerViewController *targetViewController = [TimerViewController newTimer];
		[[applicationDelegate navigationController] pushViewController: targetViewController animated: YES];

		[self setEditing: NO animated: NO];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
