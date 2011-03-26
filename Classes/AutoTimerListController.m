//
//  AutoTimerListController.m
//  dreaMote
//
//  Created by Moritz Venn on 19.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerListController.h"

#import "Constants.h"
#import "UITableViewCell+EasyInit.h"
#import "RemoteConnectorObject.h"

@implementation AutoTimerListController

@synthesize isSplit = _isSplit;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"AutoTimers", @"Title of AutoTimerListController");
		_autotimers = [[NSMutableArray array] retain];
		_refreshAutotimers = YES;
		_isSplit = NO;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_autotimers release];
	[_autotimerView release];
	[_curDocument release];

    [super dealloc];
}

/* free caches */
- (void)didReceiveMemoryWarning
{
	if(!IS_IPAD())
	{
		[_autotimerView release];
		_autotimerView = nil;
	}

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

/* getter of willReapper */
- (BOOL)willReappear
{
	return !_refreshAutotimers;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_autotimers count]) _refreshAutotimers = !new;
}

/* getter of autotimerView */
- (AutoTimerViewController *)autotimerView
{
	@synchronized(self)
	{
		if(_autotimerView == nil)
			_autotimerView = [[AutoTimerViewController alloc] init];
	}
	return _autotimerView;
}

/* setter of autotimerView */
- (void)setAutotimerView:(AutoTimerViewController *)newAutotimerView
{
	@synchronized(self)
	{
		if(_autotimerView == newAutotimerView) return;

		[_autotimerView release];
		_autotimerView = [newAutotimerView retain]; 
	}
}

/* fetch contents */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_curDocument release];
	_reloading = YES;
	_curDocument = [[[RemoteConnectorObject sharedRemoteConnector] fetchAutoTimers:self] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_autotimers removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_curDocument release];
	_curDocument = nil;
}

#pragma mark -
#pragma mark AutoTimerSourceDelegate
#pragma mark -

- (void)addAutoTimer:(AutoTimer *)at
{
	const NSUInteger idx = _autotimers.count;
	[_autotimers addObject:at];
	[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark - View lifecycle

/* load view */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kServiceCellHeight;
	_tableView.sectionHeaderHeight = 0;
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// Refresh cache
	if(_refreshAutotimers && !_reloading)
	{
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[self emptyData];

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
	}

	_refreshAutotimers = YES;
	[super viewWillAppear:animated];
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// Clean caches if supposed to
	if(_refreshAutotimers)
	{
		[self emptyData];

		if(!IS_IPAD())
		{
			[_autotimerView release];
			_autotimerView = nil;
		}
	}
	[super viewDidDisappear:animated];
}

/* support rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
	TABLEVIEWCELL_TEXT(cell) = ((AutoTimer *)[_autotimers objectAtIndex:indexPath.row]).name;

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// See if we have a valid autotimer
	AutoTimer *autotimer = [_autotimers objectAtIndex:indexPath.row];
	if(!autotimer.valid)
		return nil;
	self.autotimerView.timer = autotimer;

	// We do not want to refresh bouquet list when we return
	_refreshAutotimers = NO;

	// when in split view go back to service list, else push it on the stack
	if(!_isSplit)
		[self.navigationController pushViewController:_autotimerView animated:YES];
	return indexPath;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_autotimers count];
}

@end
