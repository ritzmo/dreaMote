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

- (void)viewDidDisappear:(BOOL)animated
{
	dist[0] = 0;
	dist[1] = 0;
	dist[2] = 0;
	dist[3] = 0;

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
		Timer* timer = [(Timer*)newTimer retain];

		int state = [timer state];

		int i;
		for(i = 3; i > state; i--){
			dist[i]++;
		}

		[_timers insertObject:timer atIndex:dist[state]++];
	}
	[self reloadData];
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

	int offset = 0;
	if(indexPath.section > 0)
		offset = dist[indexPath.section-1];
	[cell setTimer: [_timers objectAtIndex: offset + indexPath.row]];

	return cell;
}

- (void)addAction:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	TimerViewController *timerViewController = [TimerViewController newTimer];
	[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	int index = indexPath.row;
	if(indexPath.section > 0)
		index += dist[indexPath.section-1];

	Timer *timer = [_timers objectAtIndex: index];

	TimerViewController *timerViewController = [TimerViewController withTimer: timer];
	[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

	return nil;
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
