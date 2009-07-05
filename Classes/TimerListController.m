//
//  TimerListController.m
//  dreaMote
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

#import "Objects/Generic/Timer.h"

@implementation TimerListController

@synthesize timers = _timers;
@synthesize dateFormatter = _dateFormatter;

/* initialize */
- (id)init
{
	self = [super init];
	if (self) {
		self.timers = [NSMutableArray array];
		self.title = NSLocalizedString(@"Timers", @"Title of TimerListController");
		_dateFormatter = [[FuzzyDateFormatter alloc] init];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_timerViewController = nil;
		_willReappear = NO;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_timers release];
	[_dateFormatter release];
	[_timerViewController release];

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	[_timerViewController release];
	_timerViewController = nil;
	
    [super didReceiveMemoryWarning];
}

/* layout */
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

/* (un)set editing */
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

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	NSInteger i;
	
	// Reset _dist array
	for(i = 0; i < kTimerStateMax; i++)
		_dist[i] = 0;

	// Clear caches
	[_timers removeAllObjects];
	_willReappear = NO;
	[(UITableView *)self.view reloadData];
	[_timerXMLDoc release];
	_timerXMLDoc = nil;

	// Spawn a thread to fetch the timer data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchTimers) toTarget:self withObject:nil];

	[super viewWillAppear: animated];
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this
	// won't reset the editButtonItem
	if(self.editing)
		[self setEditing:NO animated: YES];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	NSInteger i;

	// Reset _dist array
	for(i = 0; i < kTimerStateMax; i++)
		_dist[i] = 0;

	// Clear Timer list
	[_timers removeAllObjects];

	// Clear remaining caches if not reappearing
	if(!_willReappear)
	{
		[_timerViewController release];
		_timerViewController = nil;
		[_timerXMLDoc release];
		_timerXMLDoc = nil;
	}

	// Reset reference date of FuzzyDateFormatter
	[_dateFormatter resetReferenceDate];
}

/* fetch timer list */
- (void)fetchTimers
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_timerXMLDoc release];
	_timerXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchTimers: self] retain];
	[pool release];
}

/* add timer to list */
- (void)addTimer: (NSObject<TimerProtocol> *)newTimer
{
	if(newTimer != nil)
	{
		NSInteger state = newTimer.state;
		NSInteger index = _dist[state];

		[_timers insertObject: newTimer atIndex: index];

		for(; state < kTimerStateMax; state++){
			_dist[state]++;
		}
#ifdef ENABLE_LAGGY_ANIMATIONS
		state = newTimer.state;
		if(state > 0)
			index -= _dist[state - 1];

		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: index inSection: state + 1]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
		[(UITableView *)self.view reloadData];
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";
	NSInteger section = indexPath.section;
	UITableViewCell *cell = nil;

	// First section, "New Timer"
	if(section == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
		if(cell == nil)
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"New Timer", @"");
		TABLEVIEWCELL_FONT(cell) = [UIFont systemFontOfSize:kTextViewFontSize]; // XXX: Looks a little weird though

		return cell;
	}

	// Timer state is section - 1, so make this a little more readable
	--section;

	// Acquire cell
	cell = [tableView dequeueReusableCellWithIdentifier:kTimerCell_ID];
	if(cell == nil)
		cell = [[[TimerTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kTimerCell_ID] autorelease];

	// Assign item
	NSInteger offset = 0;
	if(section > 0)
		offset = _dist[section-1];
	((TimerTableViewCell *)cell).formatter = _dateFormatter;
	((TimerTableViewCell *)cell).timer = [_timers objectAtIndex: offset + indexPath.row];

	return cell;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = indexPath.row;
	NSInteger section = indexPath.section - 1;
	if(section > 0)
		index += _dist[section - 1];

	NSObject<TimerProtocol> *timer = [_timers objectAtIndex: index];
	if(!timer.valid)
	{
		[tableView deselectRowAtIndexPath: indexPath animated: YES];
		return;
	}

	NSObject<TimerProtocol> *ourCopy = [timer copy];

	if(_timerViewController == nil)
		_timerViewController = [[TimerViewController alloc] init];

	_willReappear = YES;

	_timerViewController.timer = timer;
	_timerViewController.oldTimer = ourCopy;
	[ourCopy release];

	[self.navigationController pushViewController: _timerViewController animated: YES];

	// XXX: set this here so the edit button won't get screwed
	_timerViewController.creatingNewTimer = NO;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return kTimerStateMax + 1;
}

/* section title */
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

/* rows in section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	// First section only has an item when editing
	if(section == 0)
	{
		return (self.editing) ? 1 : 0;
	}
	--section;

	if(section > 0)
		return _dist[section] - _dist[section-1];
	return _dist[0];
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSInteger index = indexPath.row;
		NSInteger section = indexPath.section - 1;
		if(section > 0)
			index += _dist[section - 1];

		NSObject<TimerProtocol> *timer = [_timers objectAtIndex: index];
		if(!timer.valid)
			return;

		// Try to delete timer
		if([[RemoteConnectorObject sharedRemoteConnector] delTimer: timer])
		{
			// If we have a constant timer Id don't refresh all data
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesConstantTimerId])
			{
				for(; section < kTimerStateMax; section++){
					_dist[section]--;
				}

				[_timers removeObjectAtIndex: index];

				[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
								 withRowAnimation: UITableViewRowAnimationFade];
			}
			// Else reload data
			else
			{
				// XXX: this WILL reset our scroll position..
				for(section = 0; section < kTimerStateMax; section++)
					_dist[section] = 0;

				// Free caches
				[_timers removeAllObjects];
				[(UITableView *)self.view reloadData];
				[_timerXMLDoc release];
				_timerXMLDoc = nil;

				// Spawn a thread to fetch the timer data so that the UI is not blocked while the
				// application parses the XML file.
				[NSThread detachNewThreadSelector:@selector(fetchTimers) toTarget:self withObject:nil];
			}
		}
		// Timer could not be deleted
		else
		{
			// Alert user
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:nil
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
	// Add new Timer
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		if(_timerViewController == nil)
			_timerViewController = [[TimerViewController alloc] init];

		_willReappear = YES;

		NSObject<TimerProtocol> *newTimer = [GenericTimer timer];
		_timerViewController.timer = newTimer;
		[newTimer release];
		_timerViewController.oldTimer = nil;

		[self.navigationController pushViewController: _timerViewController animated: YES];

		// XXX: set this here so the edit button won't get screwed
		_timerViewController.creatingNewTimer = YES;
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
