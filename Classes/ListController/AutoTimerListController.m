//
//  AutoTimerListController.m
//  dreaMote
//
//  Created by Moritz Venn on 19.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

#import "AutoTimerTableViewCell.h"
#import "Objects/Generic/Result.h"

#import "Insort/NSArray+CWSortedInsert.h"
#import "UITableViewCell+EasyInit.h"

@interface AutoTimerListController()
- (void)parseEPG:(id)sender;
@end

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
		{
			AutoTimerViewController *avc = [[AutoTimerViewController alloc] init];
			self.autotimerView = avc;
			[avc release];
		}
	}
	return _autotimerView;
}

/* setter of autotimerView */
- (void)setAutotimerView:(AutoTimerViewController *)newAutotimerView
{
	@synchronized(self)
	{
		if(_autotimerView == newAutotimerView) return;

		if(_autotimerView.delegate == self)
			_autotimerView.delegate = nil;
		SafeRetainAssign(_autotimerView, newAutotimerView);
		_autotimerView.delegate = self;
	}
}

/* fetch contents */
- (void)fetchData
{
	_reloading = YES;
	SafeRetainAssign(_curDocument, [[RemoteConnectorObject sharedRemoteConnector] fetchAutoTimers:self]);
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_autotimers removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:1];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	SafeRetainAssign(_curDocument, nil);
}

/* run epg parsing on remote receiver */
- (void)parseEPGDefer
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Result *result = [[RemoteConnectorObject sharedRemoteConnector] parseAutoTimer];

	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Finished parsing EPG", @"AutoTimer", @"Force parsing is finished, this could have been either an error or a success")
														  message:result.resulttext // currently just dump the text there
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];

	[pool release];
	_parsing = NO;
}

/* initiate epg parsing on remote receiver */
- (void)parseEPG:(id)sender
{
	if(_parsing) return;
	@synchronized(self)
	{
		if(!_parsing)
			[NSThread detachNewThreadSelector:@selector(parseEPGDefer) toTarget:self withObject:nil];
		_parsing = YES;
	}
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	if([error domain] == NSURLErrorDomain)
	{
		if([error code] == 404)
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
																  message:NSLocalizedString(@"Page not found.\nPlugin not installed?", @"Connection failure with 404 in AutoTimer/EPGRefresh. Plugin probably too old or not installed.")
																 delegate:nil
														cancelButtonTitle:@"OK"
														otherButtonTitles:nil];
			[alert show];
			[alert release];
			error = nil;
		}
	}
	[super dataSourceDelegate:dataSource errorParsingDocument:document error:error];
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadData];
}

#pragma mark -
#pragma mark AutoTimerSourceDelegate
#pragma mark -

- (void)addAutoTimer:(AutoTimer *)at
{
	const NSUInteger index = [_autotimers indexForInsertingObject:at sortedUsingSelector:@selector(compare:)];
	[_autotimers insertObject:at atIndex:index];
#if INCLUDE_FEATURE(Extra_Animation)
	[_tableView reloadData];
#endif
}

#pragma mark - View lifecycle

/* load view */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kAutoTimerCellHeight;
	_tableView.sectionHeaderHeight = 0;
	_tableView.allowsSelectionDuringEditing = YES;

	// NOTE: always using toolbar now, as eventually we have to use one anyway (when adding settings), even though it looks kinda stupid on (at least) the iPad
	const UIBarButtonItem *parseButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Parse EPG", @"AutoTimer", @"Start forced parsing of EPG") style:UIBarButtonItemStyleBordered target:self action:@selector(parseEPG:)];
	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];
	NSArray *items = [[NSArray alloc] initWithObjects:flexItem, parseButton, nil];
	[self setToolbarItems:items animated:NO];
	[items release];
	[flexItem release];
	[parseButton release];

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
	[self.navigationController setToolbarHidden:NO animated:YES];

	// Refresh cache
	if(_refreshAutotimers && !_reloading)
	{
		_reloading = YES;
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[self emptyData];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
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

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	[self.navigationController setToolbarHidden:YES animated:YES];

	if(self.editing)
		[self setEditing:NO animated:animated];
	[super viewWillDisappear:animated];
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

	cell = [AutoTimerTableViewCell reusableTableViewCellInView:tableView withIdentifier:kAutoTimerCell_ID];
	((AutoTimerTableViewCell *)cell).timer = [_autotimers objectAtIndex:indexPath.row];

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.editing)
	{
		if(indexPath.section == 0)
			[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
		return nil;
	}

	// See if we have a valid autotimer
	AutoTimer *autotimer = [_autotimers objectAtIndex:indexPath.row];
	if(!autotimer.valid)
		return nil;

	// create a copy and work on it
	AutoTimer *copy = [autotimer copy];
	self.autotimerView.timer = copy;
	[copy release];

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

#pragma mark -
#pragma mark AutoTimerViewDelegate
#pragma mark -

- (void)autoTimerViewController:(AutoTimerViewController *)tvc timerWasAdded:(AutoTimer *)at
{
	[self emptyData];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)autoTimerViewController:(AutoTimerViewController *)tvc timerWasEdited:(AutoTimer *)at
{
	[self emptyData];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)autoTimerViewController:(AutoTimerViewController *)tvc editingWasCanceled:(AutoTimer *)at;
{
	// do we need this for anything?
}

@end
