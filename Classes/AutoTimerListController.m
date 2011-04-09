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

#import "Objects/Generic/Result.h"

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
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:1];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_curDocument release];
	_curDocument = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark AutoTimerSourceDelegate
#pragma mark -

- (void)addAutoTimer:(AutoTimer *)at
{
	const NSUInteger idx = _autotimers.count;
	[_autotimers addObject:at];
	[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:1]]
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

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
			[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationTop];
		}
		else
		{
			[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationTop];
		}
	}
	else
		[_tableView reloadData];
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
	UITableViewCell *cell = nil;
	// First section, "New Timer"
	if(indexPath.section == 0)
	{
		cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"New AutoTimer", @"");
		return cell;
	}

	cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
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

	// We do not want to refresh autotimer list when we return
	_refreshAutotimers = NO;

	if(!_isSplit)
		[self.navigationController pushViewController:_autotimerView animated:YES];
	else
		[_autotimerView.navigationController popToRootViewControllerAnimated:YES];

	// NOTE: set this here so the edit button won't get screwed
	_autotimerView.creatingNewTimer = NO;
	return indexPath;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 2;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	// First section only has an item when editing
	if(section == 0)
	{
		return (self.editing) ? 1 : 0;
	}
	return [_autotimers count];
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
		AutoTimer *timer = [_autotimers objectAtIndex:index];
		if(!timer.valid)
			return;

		// Try to delete timer
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] delAutoTimer:timer];
		if(result.result)
		{
			[_autotimers removeObjectAtIndex: index];
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
								 withRowAnimation:UITableViewRowAnimationFade];
		}
		// Timer could not be deleted
		else
		{
			// Alert user
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:result.resulttext
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
	// Add new Timer
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		// We do not want to refresh autotimers when we return
		_refreshAutotimers = NO;

		AutoTimer *newTimer = [AutoTimer timer];
		self.autotimerView.timer = newTimer;

		// when in split view go back to autotimer view, else push it on the stack
		if(!_isSplit)
			[self.navigationController pushViewController:_autotimerView animated:YES];
		else
		{
			[_autotimerView.navigationController popToRootViewControllerAnimated:YES];
			[self setEditing:NO animated:YES];
		}

		// NOTE: set this here so the edit button won't get screwed
		_autotimerView.creatingNewTimer = YES;
	}
}

@end
