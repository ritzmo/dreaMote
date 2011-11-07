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

#if INCLUDE_FEATURE(Extra_Animation)
	#define reloadTable() { \
		if(IS_IPHONE()) \
		[_tableView reloadData]; \
		else \
		{ \
			NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:0]; \
			[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight]; \
		} \
	}
#else
	#define reloadTable() { \
		[_tableView reloadData]; \
	}
#endif

#define setLoading() { \
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView]; \
	CGFloat topOffset = -_tableView.contentInset.top; \
	[_tableView setContentOffset:CGPointMake(0, topOffset) animated:YES]; \
}

@interface PackageManagerListController()
- (void)dataFetched;
- (void)setRegularType:(id)sender;
- (void)setInstalledType:(id)sender;
- (void)setUpgradableType:(id)sender;
- (void)doUpgrade:(id)sender;
- (void)doUpdate:(id)sender;
- (void)commitChanges:(id)sender;
- (void)abortCommit:(id)sender;
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
		_filteredPackages = [NSMutableArray array];
		_selectedPackages = [NSMutableArray array];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	_tableView.tableHeaderView = nil; // references _searchBar
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
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

	_packages = [[RemoteConnectorObject sharedRemoteConnector] packageManagementList:_listType];
	[self performSelectorOnMainThread:@selector(dataFetched) withObject:nil waitUntilDone:NO];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	_packages = nil;
	[_selectedPackages removeAllObjects]; // no use in keeping them around with new packages
	reloadTable();
}

- (void)dataFetched
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	reloadTable();
	[_tableView setContentOffset:CGPointMake(0, _searchBar.frame.size.height) animated:YES];
}

- (void)setRegularType:(id)sender
{
	if(_listType == kPackageListRegular) return;
	_listType = kPackageListRegular;

	[self configureToolbar];
	[self emptyData];
	setLoading();
	[self setEditing:YES animated:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)setInstalledType:(id)sender
{
	if(_listType == kPackageListInstalled) return;
	_listType = kPackageListInstalled;

	[self configureToolbar];
	[self emptyData];
	setLoading();
	[self setEditing:YES animated:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)setUpgradableType:(id)sender
{
	if(_listType == kPackageListUpgradable) return;
	_listType = kPackageListUpgradable;

	[self configureToolbar];
	[self emptyData];
	setLoading();
	[self setEditing:NO animated:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)doUpgradeDefer
{
	[[RemoteConnectorObject sharedRemoteConnector] packageManagementUpgrade];

	// refresh data
	[self performSelectorOnMainThread:@selector(emptyData) withObject:nil waitUntilDone:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)doUpgrade:(id)sender
{
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(doUpgradeDefer)];
}

- (void)doUpdateDefer
{
	[[RemoteConnectorObject sharedRemoteConnector] packageManagementUpdate];

	// refresh data
	[self performSelectorOnMainThread:@selector(emptyData) withObject:nil waitUntilDone:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)doUpdate:(id)sender
{
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(doUpdateDefer)];
}

- (void)doCommitChanges
{
	NSArray *selectedPackages = [_selectedPackages copy];
	[[RemoteConnectorObject sharedRemoteConnector] packageManagementCommit:selectedPackages];

	// refresh data
	_reviewingChanges = !_reviewingChanges;
	[self configureToolbar];
	[self performSelectorOnMainThread:@selector(emptyData) withObject:nil waitUntilDone:YES];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)abortCommit:(id)sender
{
	_reviewingChanges = NO;
	[self configureToolbar];
	reloadTable();
}

- (void)commitChanges:(id)sender
{
	if(_selectedPackages.count == 0)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"No packages selected", @"PackageManager", @"Title of alert when the user taps 'commit' but did not select any packages.")
															  message:nil//NSLocalizedStringFromTable(@"", @"PackageManager", @"")
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		return;
	}

	if(_reviewingChanges)
	{
		// NOTE: we might want to make sure the user actually wants to commit the changes
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(doCommitChanges)];
	}
	else
	{
		_reviewingChanges = !_reviewingChanges;
		[self configureToolbar];
		reloadTable();
	}
}

#pragma mark - View lifecycle

- (void)configureToolbar
{
	NSArray *items = nil;
	BOOL animated = NO;
	if(_reviewingChanges)
	{
		const UIBarButtonItem *abortButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Abort", @"PackageManager", @"Abort pending commit") style:UIBarButtonItemStyleBordered target:self action:@selector(abortCommit:)];
		const UIBarButtonItem *commitButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Commit", @"PackageManager", @"Commit changes made in list") style:UIBarButtonItemStyleBordered target:self action:@selector(commitChanges:)];
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																						target:nil
																						action:nil];
		items = [[NSArray alloc] initWithObjects:abortButton, flexItem, commitButton, nil];
		animated = YES;
	}
	else
	{
		const UIBarButtonItem *regularButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"All", @"PackageManager", @"All available Packages") style:UIBarButtonItemStyleBordered target:self action:@selector(setRegularType:)];
		const UIBarButtonItem *installedButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Installed", @"PackageManager", @"Installed Packages") style:UIBarButtonItemStyleBordered target:self action:@selector(setInstalledType:)];
		const UIBarButtonItem *upgradableButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Upgradable", @"PackageManager", @"Upgradable Packages") style:UIBarButtonItemStyleBordered target:self action:@selector(setUpgradableType:)];
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																						target:nil
																						action:nil];

		if(_listType == kPackageListUpgradable)
		{
			const UIBarButtonItem *upgradeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Upgrade", @"PackageManager", @"Upgrade all available packages") style:UIBarButtonItemStyleBordered target:self action:@selector(doUpgrade:)];
			items = [[NSArray alloc] initWithObjects:regularButton, installedButton, upgradableButton, flexItem, upgradeButton, nil];
		}
		else
		{
			const UIBarButtonItem *changesButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Commit", @"PackageManager", @"Commit changes made in list") style:UIBarButtonItemStyleBordered target:self action:@selector(commitChanges:)];
			items = [[NSArray alloc] initWithObjects:regularButton, installedButton, upgradableButton, flexItem, changesButton, nil];
		}
	}
	[self setToolbarItems:items animated:animated];
}

/* load view */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kPackageCellHeight;
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

	UIBarButtonItem *regularButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Update", @"PackageManager", @"Update remote list of packages") style:UIBarButtonItemStyleBordered target:self action:@selector(doUpdate:)];
	self.navigationItem.rightBarButtonItem = regularButton;
}

- (void)viewDidUnload
{
	[_filteredPackages removeAllObjects];
	_tableView.tableHeaderView = nil; // references _searchBar
	_searchBar = nil;
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	_searchDisplay = nil;

	[super viewDidUnload];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	if(_reviewingChanges)
	{
		_reviewingChanges = NO;
		[self configureToolbar];
	}
	[self.navigationController setToolbarHidden:NO animated:YES];

	// Refresh cache
	if(_refreshPackages && !_reloading)
	{
		_reloading = YES;
		[self emptyData];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[_tableView setContentOffset:CGPointMake(0, -_searchBar.frame.size.height-_tableView.contentInset.top) animated:NO];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
	if(_listType != kPackageListUpgradable)
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
		[self abortCommit:nil];
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
	NSInteger row = indexPath.row;
	if(_reviewingChanges)
	{
		if(row == 0)
		{
			UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			switch(_listType)
			{
				case kPackageListInstalled:
					cell.textLabel.text = NSLocalizedStringFromTable(@"Removed Packages:", @"PackageManager", @"Header of package list when removing packages.");
					break;
				case kPackageListRegular:
					cell.textLabel.text = NSLocalizedStringFromTable(@"Installed Packages:", @"PackageManager", @"Header of package list when installing packages.");
				default:
					break;
			}
			return cell;
		}

		packages = _selectedPackages;
		--row;
	}
	const BOOL isSearch = (tableView == _searchDisplay.searchResultsTableView);
	if(isSearch) packages = _filteredPackages;

	PackageCell *cell = [PackageCell reusableTableViewCellInView:tableView withIdentifier:kPackageCell_ID];
	cell.package = [packages objectAtIndex:row];

	// fix selection
	if([_selectedPackages containsObject:cell.package])
		[cell setMultiSelected:YES animated:NO];

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_listType == kPackageListUpgradable || (_reviewingChanges && indexPath.row == 0)) return indexPath;
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
	{
		[_selectedPackages removeObject:package];
		if(_reviewingChanges)
		{
#if INCLUDE_FEATURE(Extra_Animation)
			[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
#else
			[_tableView reloadData];
#endif
			return nil;
		}
	}
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
	if(_reviewingChanges)
		return _selectedPackages.count + 1;
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
	if(scrollView != _searchDisplay.searchResultsTableView && !_reviewingChanges)
		[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(scrollView != _searchDisplay.searchResultsTableView && !_reviewingChanges)
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
	NSArray *packages = (_reviewingChanges) ? _selectedPackages : _packages;
	for(Package *package in packages)
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
