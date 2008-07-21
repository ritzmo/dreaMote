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

static NSString *kTimerCell_ID = @"TimerCell_ID";

@synthesize timers = _timers;
@synthesize dist = _dist;

- (id)init
{
	self = [super init];
	if (self) {
		self.timers = [NSArray array];
		self.dist = [NSArray arrayWithObjects: [NSNumber numberWithInt: 0], [NSNumber numberWithInt: 0], [NSNumber numberWithInt: 0], [NSNumber numberWithInt: 0], nil];
		self.title = NSLocalizedString(@"Timers", @"");
	}
	return self;
}

- (void)dealloc
{
	[_timers release];
	[_dist release];

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

- (NSArray *)sortTimers:(NSArray *)timers
{		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"getStateString" ascending:YES] autorelease];
	return [timers sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_timers release];
	_timers = [[self sortTimers: [[RemoteConnectorObject sharedRemoteConnector] fetchTimers]] retain];

	int localDist[4] = {0, 0, 0, 0};
	for(Timer *timer in _timers){
		localDist[[timer state]]++;
	}

	[_dist release];
	_dist = [[NSArray arrayWithObjects: [NSNumber numberWithInt: localDist[0]], [NSNumber numberWithInt: localDist[1]], [NSNumber numberWithInt: localDist[2]], [NSNumber numberWithInt: localDist[3]], nil] retain];

	[(UITableView *)self.view reloadData];

	[super viewWillAppear: animated];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TimerTableViewCell *cell = (TimerTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kTimerCell_ID];
	if(cell == nil)
	{
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[TimerTableViewCell alloc] initWithFrame:cellFrame reuseIdentifier:kTimerCell_ID] autorelease];
	}

	// XXX: I really should think about the way i keep track of items in a section
	int offset = 0;
	for(int i = 0; i < indexPath.section; i++){
		offset += [[_dist objectAtIndex: i] intValue];
	}
	cell.timer = [[self timers] objectAtIndex: offset + indexPath.row];

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
			[[applicationDelegate navigationController] pushViewController: timerViewController animated: NO]; // TODO: why does this break when animated?

			//[timerViewController release];
		}
	}
	else if (buttonIndex == 1)
	{
		// Third Button: Delete
		// XXX: I'd actually add another dialogue to confirm the removal of this timer but that would require another modalView as far as I understand ;-) 
		Timer *timer = [(TimerTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: [(UITableView*)self.view indexPathForSelectedRow]] timer];
		[[RemoteConnectorObject sharedRemoteConnector] delTimer: timer];
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
	if([_dist count] < 4) // XXX: wtf?
		return 0;
		
	return [[_dist objectAtIndex: section] intValue];
}

@end
