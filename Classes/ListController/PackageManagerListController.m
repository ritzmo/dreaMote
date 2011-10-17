//
//  PackageManagerListController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "PackageManagerListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "PackageCell.h"

#import "UITableViewCell+EasyInit.h"

@interface PackageManagerListController()
- (void)dataFetched;
- (void)setRegularType:(id)sender;
- (void)setInstalledType:(id)sender;
- (void)setUpgradableType:(id)sender;
- (void)doUpgrade:(id)sender;
- (void)doUpdate:(id)sender;
- (void)commitChanges:(id)sender;
- (void)configureToolbar;
@end

@implementation PackageManagerListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Package Manager", @"Title of PackageManagerListController");
		_packages = nil;
		_refreshPackages = YES;
		_listType = kPackageListUpgradable;
		_filteredPackages = [[NSMutableArray array] retain];
		_selectedPackages = [[NSMutableArray array] retain];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	SafeRetainAssign(_packages, nil);
	SafeRetainAssign(_filteredPackages, nil);
	SafeRetainAssign(_selectedPackages, nil);
	[_filteredPackages release];
	_tableView.tableHeaderView = nil; // references _searchBar
	SafeRetainAssign(_searchBar, nil);
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	[_searchDisplay release];

    [super dealloc];
}

/* getter of willReapper */
- (BOOL)willReappear
{
	return !_refreshPackages;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_packages count]) _refreshPackages = !new;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[_tableView setEditing:editing animated:animated];
	[_searchDisplay.searchResultsTableView setEditing:editing animated:animated];
}

/* fetch contents */
- (void)fetchData
{
	_reloading = YES;

	SafeRetainAssign(_packages, [[RemoteConnectorObject sharedRemoteConnector] packageManagementList:_listType]);
	[self performSelectorOnMainThread:@selector(dataFetched) withObject:nil waitUntilDone:NO];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	SafeRetainAssign(_packages, nil);
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
}

- (void)dataFetched
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	[_tableView setContentOffset:CGPointMake(0, _searchBar.frame.size.height) animated:YES];
}

- (void)setRegularType:(id)sender
{
	if(_listType == kPackageListRegular) return;
	_listType = kPackageListRegular;

	[self configureToolbar];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)setInstalledType:(id)sender
{
	if(_listType == kPackageListInstalled) return;
	_listType = kPackageListInstalled;

	[self configureToolbar];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)setUpgradableType:(id)sender
{
	if(_listType == kPackageListUpgradable) return;
	_listType = kPackageListUpgradable;

	[self configureToolbar];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)doUpgrade:(id)sender
{
	[RemoteConnectorObject queueInvocationWithTarget:[RemoteConnectorObject sharedRemoteConnector] selector:@selector(packageManagementUpgrade)];
}

- (void)doUpdate:(id)sender
{
	[RemoteConnectorObject queueInvocationWithTarget:[RemoteConnectorObject sharedRemoteConnector] selector:@selector(packageManagementUpdate)];
}

- (void)doCommitChanges
{
	NSArray *selectedPackages = [_selectedPackages copy];
	[[RemoteConnectorObject sharedRemoteConnector] packageManagementCommit:selectedPackages];
	[selectedPackages release];
}

- (void)commitChanges:(id)sender
{
	if(_selectedPackages.count == 0)
	{
		// TODO: show alert
		return;
	}

	// NOTE: we might want to make sure the user actually wants to commit the changesgi
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(doCommitChanges)];
}

#pragma mark - View lifecycle

- (void)configureToolbar
{
	const UIBarButtonItem *regularButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"All", @"PackageManagement", @"All available Packages") style:UIBarButtonItemStyleBordered target:self action:@selector(setRegularType:)];
	const UIBarButtonItem *installedButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Installed", @"PackageManagement", @"Installed Packages") style:UIBarButtonItemStyleBordered target:self action:@selector(setInstalledType:)];
	const UIBarButtonItem *upgradableButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Upgradable", @"PackageManagement", @"Upgradable Packages") style:UIBarButtonItemStyleBordered target:self action:@selector(setUpgradableType:)];
	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];

	NSArray *items = nil;
	if(_listType == kPackageListUpgradable)
	{
		const UIBarButtonItem *upgradeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Upgrade", @"PackageManagement", @"Upgrade all available packages") style:UIBarButtonItemStyleBordered target:self action:@selector(doUpgrade:)];
		items = [[NSArray alloc] initWithObjects:regularButton, installedButton, upgradableButton, flexItem, upgradeButton, nil];
		[upgradeButton release];
	}
	else
	{
		const UIBarButtonItem *changesButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Commit", @"PackageManagement", @"Commit changes made in list") style:UIBarButtonItemStyleBordered target:self action:@selector(commitChanges:)];
		items = [[NSArray alloc] initWithObjects:regularButton, installedButton, upgradableButton, flexItem, changesButton, nil];
		[changesButton release];
	}
	[self setToolbarItems:items animated:NO];
	[items release];
	[flexItem release];
	[upgradableButton release];
	[installedButton release];
	[regularButton release];
}

/* load view */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kAutoTimerCellHeight;
	_tableView.sectionHeaderHeight = 0;
	_tableView.allowsSelectionDuringEditing = YES;

	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
	_searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	_searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_searchBar.keyboardType = UIKeyboardTypeDefault;
	_tableView.tableHeaderView = _searchBar;

	// hide the searchbar
	[_tableView setContentOffset:CGPointMake(0, _searchBar.frame.size.height)];

	_searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
	_searchDisplay.delegate = self;
	_searchDisplay.searchResultsDataSource = self;
	_searchDisplay.searchResultsDelegate = self;

	[self configureToolbar];

	UIBarButtonItem *regularButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Update", @"PackageManagement", @"Update remote list of packages") style:UIBarButtonItemStyleBordered target:self action:@selector(doUpdate:)];
	self.navigationItem.rightBarButtonItem = regularButton;
	[regularButton release];
}

- (void)viewDidUnload
{
	[_filteredPackages removeAllObjects];
	_tableView.tableHeaderView = nil; // references _searchBar
	SafeRetainAssign(_searchBar, nil);
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	SafeRetainAssign(_searchDisplay, nil);

	[super viewDidUnload];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	[self.navigationController setToolbarHidden:NO animated:YES];

	// Refresh cache
	if(_refreshPackages && !_reloading)
	{
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[self emptyData];
		// NOTE: offset is a little off on iPad iOS 4.2, but this is the best looking version on everything else
		[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
	[self setEditing:YES animated:animated];

	_refreshPackages = YES;
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
	if(_refreshPackages)
	{
		[self emptyData];
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
	NSArray *packages = _packages;
	const BOOL isSearch = (tableView == _searchDisplay.searchResultsTableView);
	if(isSearch) packages = _filteredPackages;

	PackageCell *cell = [PackageCell reusableTableViewCellInView:tableView withIdentifier:kPackageCell_ID];
	cell.package = [packages objectAtIndex:indexPath.row];

	// fix selection from before this search
	if(isSearch)
	{
		if([_selectedPackages containsObject:cell.package])
			[cell setMultiSelected:YES animated:NO];
	}

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Package *package = nil;
	BOOL selected = YES;
	if(tableView == _searchDisplay.searchResultsTableView)
	{
		// NOTE: overly complicated because we change selection in both tables
		PackageCell *cell = (PackageCell *)[tableView cellForRowAtIndexPath:indexPath];
		selected = [cell toggleMultiSelected];

		package = cell.package;
		NSInteger idx = [_packages indexOfObject:package];
		NSIndexPath *idxPath = [NSIndexPath indexPathForRow:idx inSection:0];
		cell = (PackageCell *)[_tableView cellForRowAtIndexPath:idxPath];
		[cell toggleMultiSelected];
	}
	else
	{
		PackageCell *cell = (PackageCell *)[tableView cellForRowAtIndexPath:indexPath];
		selected = [cell toggleMultiSelected];
		package = cell.package;
	}

	if(selected)
		[_selectedPackages addObject:package];
	else
		[_selectedPackages removeObject:package];
	return indexPath;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(tableView == _searchDisplay.searchResultsTableView)
		return _filteredPackages.count;
	return _packages.count;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if(scrollView != _searchDisplay.searchResultsTableView)
		[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(scrollView != _searchDisplay.searchResultsTableView)
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
#pragma mark -

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[_filteredPackages removeAllObjects];
	const BOOL caseInsensitive = [searchString isEqualToString:[searchString lowercaseString]];
	NSStringCompareOptions options = caseInsensitive ? (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) : 0;
	for(Package *package in _packages)
	{
		NSRange range = [package.name rangeOfString:searchString options:options];
		if(range.length)
			[_filteredPackages addObject:package];
	}

	return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)searchTableView
{
	searchTableView.rowHeight = _tableView.rowHeight;
	[searchTableView setEditing:YES];
	searchTableView.allowsSelectionDuringEditing = YES;
	[searchTableView reloadData];
}

@end
