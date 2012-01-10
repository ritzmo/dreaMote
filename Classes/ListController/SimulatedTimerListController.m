//
//  SimulatedTimerListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright 2012 Moritz Venn. All rights reserved.
//

#import "SimulatedTimerListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

#import <Objects/Generic/Result.h>
#import <Objects/Generic/SimulatedTimer.h>

#import "Insort/NSArray+CWSortedInsert.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/SimulatedTimerTableViewCell.h>

#import <XMLReader/BaseXMLReader.h>

#import "MBProgressHUD.h"

@interface SimulatedTimerListController()
- (void)switchSort:(id)sender;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) BOOL sortTitle;
@end

@implementation SimulatedTimerListController

@synthesize dateFormatter, isSlave;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedStringFromTable(@"Preview", @"AutoTimer", @"Title of SimulatedTimerListController");
		_timers = [NSMutableArray array];
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_sortTitle = NO;
	}
	return self;
}

/* fetch contents */
- (void)fetchData
{
	_reloading = YES;
	NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
	_xmlReader = [sharedRemoteConnector simulateAutoTimers:self];
}

/* remove content data */
- (void)emptyData
{
	// Clean timer list
	[_timers removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	_xmlReader = nil;
}

- (BOOL)sortTitle
{
	return _sortTitle;
}

- (void)setSortTitle:(BOOL)sortTitle
{
	_sortTitle = sortTitle;
	if(sortTitle)
		[_timers sortUsingSelector:@selector(autotimerCompare:)];
	else
		[_timers sortUsingSelector:@selector(timeCompare:)];
}

- (void)switchSort:(id)sender
{
	self.sortTitle = !_sortTitle;
	if(_sortTitle)
		_sortButton.title = NSLocalizedString(@"Sort by time", @"Sort (movies) by time");
	else
		_sortButton.title = NSLocalizedStringFromTable(@"Sort AutoTimer", @"AutoTimer", @"Sort list by AutoTimer name");

	[_tableView reloadData];
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error
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
			error = nil;
		}
	}
	[super dataSourceDelegate:dataSource errorParsingDocument:error];
}

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	self.sortTitle = _sortTitle; // sort
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadData];
}

#pragma mark -
#pragma mark TimerSourceDelegate
#pragma mark -

- (void)addTimer:(NSObject<TimerProtocol> *)timer
{
	[_timers addObject:timer];
}

- (void)addTimers:(NSArray *)items
{
	[_timers addObjectsFromArray:items];
}

#pragma mark - View lifecycle

/* load view */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = [DreamoteConfiguration singleton].simulatedTimerCellHeight;
	_tableView.sectionHeaderHeight = 0;
	_tableView.allowsSelectionDuringEditing = YES;

	_sortButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleBordered target:self action:@selector(switchSort:)];
	if(_sortTitle)
		_sortButton.title = NSLocalizedString(@"Sort by time", @"Sort (movies) by time");
	else
		_sortButton.title = NSLocalizedStringFromTable(@"Sort AutoTimer", @"AutoTimer", @"Sort list by AutoTimer name");
	self.navigationItem.rightBarButtonItem = _sortButton;

	[self theme];
}

- (void)viewDidUnload
{
	_sortButton = nil;
	[super viewDidUnload];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// Refresh cache
	if(!_reloading)
	{
		_reloading = YES;
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[self emptyData];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}

	[super viewWillAppear:animated];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	// Reset reference date of date formatter
	[dateFormatter resetReferenceDate];
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
	UITableViewCell *cell = [SimulatedTimerTableViewCell reusableTableViewCellInView:tableView withIdentifier:kSimulatedTimerCell_ID];
	((SimulatedTimerTableViewCell *)cell).formatter = dateFormatter;
	((SimulatedTimerTableViewCell *)cell).timer = [_timers objectAtIndex:indexPath.row];

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave];
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_timers count];
}

/* did select row */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
