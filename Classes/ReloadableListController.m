//
//  ReloadableListController.m
//  dreaMote
//
//  Created by Moritz Venn on 06.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "ReloadableListController.h"

@implementation ReloadableListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_reloading = NO;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_refreshHeaderView release];
	[_tableView release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	// create table view
	_tableView = [[SwipeTableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// setup our content view so that it auto-rotates along with the UViewController
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = _tableView;

	// add header view
	_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
	_refreshHeaderView.delegate = self;
	[self.view addSubview:_refreshHeaderView];
}

- (void)loadGroupedTableView
{
	// create table view
	_tableView = [[SwipeTableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

	// setup our content view so that it auto-rotates along with the UViewController
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = _tableView;

	// add header view
	// NOTE: looks ugly on ipad, so only enable this on iphone for now
	if(!IS_IPAD())
	{
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.view addSubview:_refreshHeaderView];
	}
}

/* view did appear */
- (void)viewDidAppear:(BOOL)animated
{
	if(_reloading)
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
}

#pragma mark -
#pragma mark ReloadableView methods
#pragma mark -

/* start download of content data */
- (void)fetchData
{
	// subclasses should override this
}

/* remove content data */
- (void)emptyData
{
	// subclasses should override this
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadData];

	// Alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
#pragma mark -

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	if(_reloading) return;
	[self emptyData];

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return _reloading;
}

@end
