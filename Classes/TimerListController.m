//
//  TimerListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "TimerListController.h"

#import "TimerViewController.h"

#import "NSDateFormatter+FuzzyFormatting.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "TimerTableViewCell.h"

#import "Objects/Generic/Timer.h"
#import "Objects/Generic/Result.h"

@implementation TimerListController

@synthesize timers = _timers;
@synthesize dateFormatter = _dateFormatter;
@synthesize isSplit = _isSplit;
@synthesize timerViewController = _timerViewController;
@synthesize willReappear = _willReappear;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.timers = [NSMutableArray array];
		self.title = NSLocalizedString(@"Timers", @"Title of TimerListController");
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_timerViewController = nil;
		_willReappear = NO;
		_isSplit = NO;
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
	if(!IS_IPAD())
	{
		[_timerViewController release];
		_timerViewController = nil;
	}
	
    [super didReceiveMemoryWarning];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 62;

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setWillReappear:(BOOL)new
{
	// allow to skip refresh only if there is any data
	/*
	 @note this prevents problems with iOS3.2 where sections were not properly reloaded
	 resulting in double section headers with the first set hiding the first timer.
	 */
	if(_dist[0] > 0) _willReappear = new;
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[_tableView setEditing: editing animated: animated];

	if(animated)
	{
		if(editing)
		{
			[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationTop];
		}
		else
		{
			[_tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:0 inSection:0]]
							withRowAnimation: UITableViewRowAnimationTop];
		}
	}
	else
		[_tableView reloadData];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	if(!_willReappear)
	{
		[self emptyData];

		// Spawn a thread to fetch the timer data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
		[_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
	}

	_willReappear = NO;

	[super viewWillAppear: animated];
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this won't reset the editButtonItem
	if(self.editing)
		[self setEditing:NO animated: YES];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	// Clear remaining caches if not reappearing
	if(!_willReappear)
	{
		if(!IS_IPAD())
		{
			[_timerViewController release];
			_timerViewController = nil;

			[self emptyData];
		}
	}

	// Reset reference date of date formatter
	[_dateFormatter resetReferenceDate];
}

/* fetch timer list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_timerXMLDoc release];
	_reloading = YES;
	_timerXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchTimers: self] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	NSUInteger i = 0;

	// Clean timer list
	for(i = 0; i < kTimerStateMax; i++)
		_dist[i] = 0;
	[_timers removeAllObjects];

	/*!
	 @note at least 3.2 has problems with repositioning the section titles, so only do a
	 "pretty" reload on 4.0+
	 */
	float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	if(currentVersion >= 4.0f)
	{
		NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, kTimerStateMax + 1)];
		[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	}
	else
	{
		[_tableView reloadData];
	}

	[_timerXMLDoc release];
	_timerXMLDoc = nil;
}

/* add timer to list */
- (void)addTimer: (NSObject<TimerProtocol> *)newTimer
{
	if(newTimer != nil)
	{
		NSUInteger state = newTimer.state;
		NSUInteger index = _dist[state];

		[_timers insertObject: newTimer atIndex: index];

		for(; state < kTimerStateMax; state++){
			_dist[state]++;
		}
#ifdef ENABLE_LAGGY_ANIMATIONS
		state = newTimer.state;
		if(state > 0)
			index -= _dist[state - 1];

		[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: index inSection: state + 1]]
						withRowAnimation: UITableViewRowAnimationTop];
#endif
	}
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *cell = nil;

	// First section, "New Timer"
	if(section == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
		if(cell == nil)
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"New Timer", @"");
		TABLEVIEWCELL_FONT(cell) = [UIFont systemFontOfSize:kTextViewFontSize]; // FIXME: Looks a little weird though

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
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = indexPath.row;
	const NSInteger section = indexPath.section - 1;
	if(section > 0)
		index += _dist[section - 1];

	NSObject<TimerProtocol> *timer = [_timers objectAtIndex: index];
	if(!timer.valid)
	{
		[tableView deselectRowAtIndexPath: indexPath animated: YES];
		return nil;
	}

	NSObject<TimerProtocol> *ourCopy = [timer copy];

	if(_timerViewController == nil)
		_timerViewController = [[TimerViewController alloc] init];

	if(!IS_IPAD())
		_willReappear = YES;

	_timerViewController.delegate = self;
	_timerViewController.timer = timer;
	_timerViewController.oldTimer = ourCopy;
	[ourCopy release];

	// when in split view go back to timer view, else push it on the stack
	if(!_isSplit)
		[self.navigationController pushViewController: _timerViewController animated:YES];
	else
		[_timerViewController.navigationController popToRootViewControllerAnimated: YES];

	// NOTE: set this here so the edit button won't get screwed
	_timerViewController.creatingNewTimer = NO;
	return indexPath;
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
		NSUInteger index = indexPath.row;
		NSUInteger section = indexPath.section - 1;
		if(section > 0)
			index += _dist[section - 1];

		NSObject<TimerProtocol> *timer = [_timers objectAtIndex: index];
		if(!timer.valid)
			return;

		// Try to delete timer
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] delTimer: timer];
		if(result.result)
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
				// NOTE: this WILL reset our scroll position..
				[self emptyData];

				// Spawn a thread to fetch the timer data so that the UI is not blocked while the
				// application parses the XML file.
				[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
			}
		}
		// Timer could not be deleted
		else
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:result.resulttext
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

		if(!IS_IPAD())
			_willReappear = YES;

		NSObject<TimerProtocol> *newTimer = [GenericTimer timer];
		_timerViewController.delegate = self;
		_timerViewController.timer = newTimer;
		_timerViewController.oldTimer = nil;

		// when in split view go back to timer view, else push it on the stack
		if(!_isSplit)
			[self.navigationController pushViewController: _timerViewController animated:YES];
		else
		{
			[_timerViewController.navigationController popToRootViewControllerAnimated: YES];
			[self setEditing:NO animated:YES];
		}

		// NOTE: set this here so the edit button won't get screwed
		_timerViewController.creatingNewTimer = YES;
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark TimerViewControllerDelegate
#pragma mark -

- (void)timerViewController:(TimerViewController *)tvc timerWasAdded:(NSObject<TimerProtocol> *)timer
{
	// TODO: check if we can implement optimized reload
	[self emptyData];
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

- (void)timerViewController:(TimerViewController *)tvc timerWasEdited:(NSObject<TimerProtocol> *)timer :(NSObject<TimerProtocol> *)oldTimer;
{
	// TODO: check if we can implement optimized reload
	[self emptyData];
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

- (void)timerViewController:(TimerViewController *)tvc editingWasCanceled:(NSObject<TimerProtocol> *)timer;
{
	// do we need this for anything?
}

@end
