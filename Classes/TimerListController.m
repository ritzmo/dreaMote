//
//  TimerListController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerListController.h"

#import "TimerViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"
#import "FuzzyDateFormatter.h"

#import "TimerTableViewCell.h"

@implementation TimerListController

@synthesize timers = _timers;
@synthesize dateFormatter;

- (id)init
{
	self = [super init];
	if (self) {
		self.timers = [NSMutableArray array];
		self.title = NSLocalizedString(@"Timers", @"Title of TimerListController");
		self.dateFormatter = [[FuzzyDateFormatter alloc] init];
		[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		timerViewController = nil;
		_willReappear = NO;
	}
	return self;
}

- (void)dealloc
{
	[_timers release];
	[dateFormatter release];
	[timerViewController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[timerViewController release];
	timerViewController = nil;
	
    [super didReceiveMemoryWarning];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[(UITableView*)self.view setEditing: editing animated: animated];

	if(animated)
	{
		if(editing)
		{
			[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationTop];
		}
		else
		{
			[(UITableView*)self.view deleteRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationTop];
		}
	}
	else
		[(UITableView *)self.view reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSInteger i;
	for(i = 0; i < kTimerStateMax; i++)
		dist[i] = 0;

	[_timers removeAllObjects];
	_willReappear = NO;

	[(UITableView *)self.view reloadData];

	// Spawn a thread to fetch the timer data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchTimers) toTarget:self withObject:nil];

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this
	// won't reset the editButtonItem
	if(self.editing)
		[self setEditing:NO animated: YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
	NSInteger i;
	for(i = 0; i < kTimerStateMax; i++)
		dist[i] = 0;

	[_timers removeAllObjects];

	if(!_willReappear)
	{
		[timerViewController release];
		timerViewController = nil;
	}

	[dateFormatter resetReferenceDate];
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
		NSInteger index = dist[state];

		[_timers insertObject:timer atIndex:index];

		for(; state < kTimerStateMax; state++){
			dist[state]++;
		}
#ifdef ENABLE_LAGGY_ANIMATIONS
		state = timer.state;
		if(state > 0)
			index -= dist[state - 1];

		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: index inSection: state + 1]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
		[(UITableView *)self.view reloadData];
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

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
	((TimerTableViewCell *)cell).formatter = dateFormatter;
	((TimerTableViewCell *)cell).timer = [_timers objectAtIndex: offset + indexPath.row];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = indexPath.row;
	NSInteger section = indexPath.section - 1;
	if(section > 0)
		index += dist[section - 1];

	Timer *timer = [_timers objectAtIndex: index];
	if(!timer.valid)
	{
		[tableView deselectRowAtIndexPath: indexPath animated: YES];
		return;
	}

	Timer *ourCopy = [timer copy];

	if(timerViewController == nil)
		timerViewController = [[TimerViewController alloc] init];

	_willReappear = YES;

	timerViewController.timer = timer;
	timerViewController.oldTimer = ourCopy;
	[ourCopy release];

	[self.navigationController pushViewController: timerViewController animated: YES];

	// XXX: set this here so the edit button won't get screwed
	timerViewController.creatingNewTimer = NO;
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
	if(section == 0)
	{
		return (self.editing) ? 1 : 0;
	}
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
		NSInteger index = indexPath.row;
		NSInteger section = indexPath.section - 1;
		if(section > 0)
			index += dist[section - 1];

		if([[RemoteConnectorObject sharedRemoteConnector] delTimer: [_timers objectAtIndex: index]])
		{
			for(; section < kTimerStateMax; section++){
				dist[section]--;
			}

			[_timers removeObjectAtIndex: index];

			[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
							 withRowAnimation: UITableViewRowAnimationFade];
		}
		else
		{
			// alert user if timer could not be deleted
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:nil
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		if(timerViewController == nil)
			timerViewController = [[TimerViewController alloc] init];

		_willReappear = YES;

		Timer *newTimer = [Timer timer];
		timerViewController.timer = newTimer;
		[newTimer release];
		timerViewController.oldTimer = nil;

		[self.navigationController pushViewController: timerViewController animated: YES];

		// XXX: set this here so the edit button won't get screwed
		timerViewController.creatingNewTimer = YES;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
