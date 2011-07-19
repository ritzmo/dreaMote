//
//  MovieListController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MovieListController.h"

#import "MovieTableViewCell.h"
#import "MovieViewController.h"

#import "Constants.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"
#import "UIDevice+SystemVersion.h"

#import <Objects/MovieProtocol.h>

#import <Objects/Generic/Result.h>

@interface MovieListController()
- (void)setSortTitle:(BOOL)newSortTitle allowSearch:(BOOL)allowSearch;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, assign) BOOL sortTitle;
@end

@implementation MovieListController

@synthesize popoverController;
@synthesize isSplit = _isSplit;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");
		_movies = [[NSMutableArray alloc] init];
		_characters = [[NSMutableDictionary alloc] init];
#if IS_FULL()
		_filteredMovies = [[NSMutableArray alloc] init];
#endif
		_refreshMovies = YES;
		_isSplit = NO;

		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];

		_movieViewController = nil;

		NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
		_sortTitle = [stdDefaults boolForKey:kSortMoviesByTitle];

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
		{
			self.contentSizeForViewInPopover = CGSizeMake(370.0f, 600.0f);
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_movies release];
	[_characters release];
	[_currentKeys release];
	[_dateFormatter release];
	self.movieViewController = nil;
	[_movieXMLDoc release];
	[_sortButton release];
#if IS_FULL()
	[_filteredMovies release];
	_tableView.tableHeaderView = nil; // references _searchBar
	[_searchBar release];
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	[_searchDisplay release];
#endif

	[super dealloc];
}

/* getter of currentLocation property */
- (NSString *)currentLocation
{
	return _currentLocation;
}

/* setter of currentLocation property */
- (void)setCurrentLocation: (NSString *)newLocation
{
	if(_currentLocation == newLocation ||
	   [_currentLocation isEqualToString: newLocation]) return;
	SafeRetainAssign(_currentLocation, newLocation);

	// Set Title
	if(newLocation)
		self.title = newLocation;
	else
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");

	// Free Caches and reload data
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
	// NOTE: offset is a little off on iPad iOS 4.2, but this is the best looking version on everything else
	[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
#endif

	// Eventually remove popover
	if(self.popoverController != nil) {
		[self.popoverController dismissPopoverAnimated:YES];
	}

	_refreshMovies = NO;
	// Spawn a thread to fetch the movie data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

/* getter of reloading */
- (BOOL)reloading
{
	return _reloading;
}

/* getter of willReapper */
- (BOOL)willReappear
{
	return !_refreshMovies;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_movies count]) _refreshMovies = !new;
}

/* getter of movieViewController */
- (MovieViewController *)movieViewController
{
	if(_movieViewController == nil)
	{
		@synchronized(self)
		{
			if(_movieViewController == nil)
			{
				_movieViewController = [[MovieViewController alloc] init];
				_movieViewController.movieList = self;
			}
		}
	}
	return _movieViewController;
}

/* setter of movieViewController */
- (void)setMovieViewController:(MovieViewController *)new
{
	@synchronized(self)
	{
		if(new == _movieViewController) return;

		if(_movieViewController && _movieViewController.movieList == self)
			_movieViewController.movieList = nil;
		SafeRetainAssign(_movieViewController, new);
		if(_movieViewController)
			_movieViewController.movieList = self;
	}
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	if(IS_IPHONE())
		self.movieViewController = nil;

	[super didReceiveMemoryWarning];
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[_tableView setEditing: editing animated: animated];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordDelete])
	{
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																						target:nil
																						action:nil];
		NSArray *items = nil;

		if(IS_IPAD())
		{
			UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 190, self.navigationController.navigationBar.frame.size.height)];
			items = [[NSArray alloc] initWithObjects:flexItem, _sortButton, self.editButtonItem, nil];
			[toolbar setItems:items animated:NO];
			UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

			self.navigationItem.rightBarButtonItem = buttonItem;

			[buttonItem release];
			[toolbar release];
		}
		else
		{
			items = [[NSArray alloc] initWithObjects:_sortButton, flexItem, self.editButtonItem, nil];
			[self setToolbarItems:items animated:NO];
			[self.navigationController setToolbarHidden:NO animated:YES];

			self.navigationItem.rightBarButtonItem = nil;
		}
		[items release];
		[flexItem release];
	}
	else
		self.navigationItem.rightBarButtonItem = _sortButton;

	if(_refreshMovies && !_reloading)
	{
		[self emptyData];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
		[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top)];
#endif

		// Spawn a thread to fetch the movie data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
	}

	_refreshMovies = YES;

	[super viewWillAppear: animated];
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(IS_IPHONE())
		[self.navigationController setToolbarHidden:YES animated:YES];

	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this wouldn't reset the editButtonItem
	if(self.editing)
		[self setEditing:NO animated: YES];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	// Free caches if supposed to
	if(_refreshMovies)
	{
		[_movies removeAllObjects];
		if(IS_IPHONE())
			self.movieViewController = nil;
		SafeRetainAssign(_movieXMLDoc, nil);
	}

	[_dateFormatter resetReferenceDate];
}

- (void)didReconnect:(NSNotification *)note
{
	/*!
	 @brief reset current location
	 @note do not refresh immediately, so don't use self.currentLocation setter
	 */
	if(_currentLocation)
	{
		SafeRetainAssign(_currentLocation, nil);
		_refreshMovies = YES;
	}

	// reset shown movie
	if(_movieViewController)
		_movieViewController.movie = nil;
}

- (BOOL)sortTitle
{
	return _sortTitle;
}

- (void)setSortTitle:(BOOL)newSortTitle allowSearch:(BOOL)allowSearch
{
	_sortTitle = newSortTitle;

	NSArray *movies = _movies;
#if IS_FULL()
	if(allowSearch && _searchDisplay.active) movies = _filteredMovies;
#endif
	if(!movies.count)
	{
		[_characters removeAllObjects];
		SafeRetainAssign(_currentKeys, nil);
		return;
	}

	if(newSortTitle)
	{
		NSArray *arr = nil;
		[_characters removeAllObjects];

		for(NSString *index in [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil ])
		{
			NSPredicate *pred = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"title beginswith[c] '%@'", index]];
			arr = [movies filteredArrayUsingPredicate:pred];
			if(arr.count)
				[_characters setValue:[arr sortedArrayUsingSelector:@selector(titleCompare:)] forKey:index];
		}
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"title matches '(\\\\d|\\\\s).*'"];
		arr = [movies filteredArrayUsingPredicate:pred];
		if(arr.count)
			[_characters setValue:[arr sortedArrayUsingSelector:@selector(titleCompare:)] forKey:@"#"];

		SafeRetainAssign(_currentKeys, [[_characters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]);
	}
	else
	{
		[_characters removeAllObjects];
		SafeRetainAssign(_currentKeys, nil);
	}
}

- (void)setSortTitle:(BOOL)newSortTitle
{
	[self setSortTitle:newSortTitle allowSearch:YES];
}

- (void)switchSort:(id)sender
{
	self.sortTitle = !_sortTitle;
	if(_sortTitle)
		_sortButton.title = NSLocalizedString(@"Sort by time", @"Sort (movies) by time");
	else
		_sortButton.title = NSLocalizedString(@"Sort A-Z", @"Sort (movies) alphabetically");

	[_tableView reloadData];

	// save sorting preferences
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	[stdDefaults setBool:_sortTitle forKey:kSortMoviesByTitle];
	[stdDefaults synchronize];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;

	_sortButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleBordered target:self action:@selector(switchSort:)];
	if(_sortTitle)
		_sortButton.title = NSLocalizedString(@"Sort by time", @"Sort (movies) by time");
	else
		_sortButton.title = NSLocalizedString(@"Sort A-Z", @"Sort (movies) alphabetically");

#if IS_FULL()
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
#endif

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReconnect:) name:kReconnectNotification object:nil];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_characters removeAllObjects];
	[_movies removeAllObjects];
	SafeRetainAssign(_currentKeys, nil);
	SafeRetainAssign(_sortButton, nil);
#if IS_FULL()
	[_filteredMovies removeAllObjects];
	_tableView.tableHeaderView = nil; // references _searchBar
	SafeRetainAssign(_searchBar, nil);
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	SafeRetainAssign(_searchDisplay, nil);
#endif

	[super viewDidUnload];
}

/* fetch movie list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	_reloading = YES;
	SafeRetainAssign(_movieXMLDoc, [[RemoteConnectorObject sharedRemoteConnector] fetchMovielist:self withLocation:_currentLocation]);
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean movie list(s)
	[_characters removeAllObjects];
	[_movies removeAllObjects];
	SafeRetainAssign(_currentKeys, nil);
#if INCLUDE_FEATURE(Extra_Animation)
	if(_sortTitle)
	{
		[_tableView reloadData];
	}
	else
	{
		NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
		[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	}
#else
	[_tableView reloadData];
#endif
	SafeRetainAssign(_movieXMLDoc, nil);
}

/* select and return next movie */
- (NSObject<MovieProtocol> *)nextMovie
{
	UITableView *tableView = _tableView;
#if IS_FULL()
	if(_searchDisplay.active) tableView = _searchDisplay.searchResultsTableView;
#endif
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];

	if(_sortTitle)
	{
		NSString *key = [_currentKeys objectAtIndex:indexPath.section];
		NSArray *movies = (NSArray *)[_characters valueForKey:key];
		if(indexPath.row < movies.count - 1)
			indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
		else if(indexPath.section < _currentKeys.count - 1)
			indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
		else
			indexPath = nil;
	}
	else
	{
		NSArray *movies = _movies;
#if IS_FULL()
		if(_searchDisplay.active) movies = _filteredMovies;
#endif
		if(indexPath.row < ([movies count] - 1))
			indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
		else
			indexPath = nil;
	}

	if(indexPath)
	{
		[tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		MovieTableViewCell *cell = (MovieTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
		return cell.movie;
	}
	return nil;
}

/* select and return previous movie */
- (NSObject<MovieProtocol> *)previousMovie
{
	UITableView *tableView = _tableView;
#if IS_FULL()
	if(_searchDisplay.active) tableView = _searchDisplay.searchResultsTableView;
#endif
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];

	if(_sortTitle)
	{
		if(indexPath.row > 0)
			indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
		else if(indexPath.section > 0)
			indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section - 1];
		else
			indexPath = nil;
	}
	else
	{
		if(indexPath.row > 0)
			indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
		else
			indexPath = nil;
	}

	if(indexPath)
	{
		[tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		MovieTableViewCell *cell = (MovieTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
		return cell.movie;
	}
	return nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	if(_isSplit)
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
		_reloading = NO;
	}
	else
	{
		[super dataSourceDelegate:dataSource errorParsingDocument:document error:error];
	}
#if IS_FULL()
	[_tableView setContentOffset:CGPointMake(0, _searchBar.frame.size.height) animated:YES];
#endif
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	if(_sortTitle)
	{
		self.sortTitle = _sortTitle;
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
	}
	else
	{
		[super dataSourceDelegate:dataSource finishedParsingDocument:document];
	}
#if IS_FULL()
	[_tableView setContentOffset:CGPointMake(0, _searchBar.frame.size.height) animated:YES];
#endif
}

#pragma mark -
#pragma mark MovieSourceDelegate methods
#pragma mark -

/* add movie to list */
- (void)addMovie: (NSObject<MovieProtocol> *)movie
{
	[_movies addObject: movie];
	if(!_sortTitle)
	{
#if INCLUDE_FEATURE(Extra_Animation)
		const NSUInteger idx = _movies.count-1;
		[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]]
						  withRowAnimation:UITableViewRowAnimationLeft];
#endif
	}
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* height for row */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kUIRowHeight;
}

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MovieTableViewCell *cell = [MovieTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMovieCell_ID];

	cell.formatter = _dateFormatter;
	if(_sortTitle)
	{
		NSString *key = [_currentKeys objectAtIndex:indexPath.section];
		cell.movie = [(NSArray *)[_characters valueForKey:key] objectAtIndex:indexPath.row];
	}
	else
	{
		NSArray *movies = _movies;
#if IS_FULL()
		if(tableView == _searchDisplay.searchResultsTableView) movies = _filteredMovies;
#endif
		cell.movie = [movies objectAtIndex:indexPath.row];
	}

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		[NSException raise:@"MovieListUserInteractionWhileReloading" format:@"willSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return nil;
	}

	NSObject<MovieProtocol> *movie = nil;
	if(_sortTitle)
	{
		NSString *key = [_currentKeys objectAtIndex:indexPath.section];
		movie = [(NSArray *)[_characters valueForKey:key] objectAtIndex:indexPath.row];
	}
	else
	{
		NSArray *movies = _movies;
#if IS_FULL()
		if(tableView == _searchDisplay.searchResultsTableView) movies = _filteredMovies;
#endif
		movie = [movies objectAtIndex:indexPath.row];
	}

	if(!movie.valid)
		return nil;

	self.movieViewController.movie = movie;

	if(!_isSplit)
	{
		// XXX: wtf?
		if([self.navigationController.viewControllers containsObject:_movieViewController])
		{
#if IS_DEBUG()
			NSMutableString* result = [[NSMutableString alloc] init];
			for(NSObject* obj in self.navigationController.viewControllers)
				[result appendString:[obj description]];
			[NSException raise:@"MovieViewTwiceInNavigationStack" format:@"_movieViewController was twice in navigation stack: %@", result];
			[result release]; // never reached, but to keep me from going crazy :)
#endif
			[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
		}
		[self.navigationController pushViewController: _movieViewController animated: YES];
	}

	_refreshMovies = NO;

	return indexPath;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(_sortTitle)
	{
		return [_currentKeys count];
	}
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_sortTitle)
		return [_currentKeys objectAtIndex:section];
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
#ifndef defaultSectionHeaderHeight
#define defaultSectionHeaderHeight 34
#endif
	if(_sortTitle)
		return defaultSectionHeaderHeight;
	return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	if(_sortTitle)
	{
		return _currentKeys;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return index; // XXX: wtf?
}

/* row count */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(_sortTitle)
	{
		NSString *key = [_currentKeys objectAtIndex:section];
		return ((NSArray *)[_characters valueForKey:key]).count;
	}
#if IS_FULL()
	if(tableView == _searchDisplay.searchResultsTableView) return _filteredMovies.count;
#endif
	return [_movies count];
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
#if IS_DEBUG()
	if(indexPath == nil)
	{
		[NSException raise:@"MovieListControllerIndexPathIsNil" format:@"indexPath was nil inside tableView:commitEditingStyle:forRowAtIndexPath:"];
	}
#endif

	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		[NSException raise:@"MovieListUserInteractionWhileReloading" format:@"commintEditingStyle was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return;
	}

	// NOTE: search able will never be editing, so no special handling
	NSObject<MovieProtocol> *movie = nil;
	if(_sortTitle)
	{
		NSString *key = [_currentKeys objectAtIndex:indexPath.section];
		movie = [(NSArray *)[_characters valueForKey:key] objectAtIndex:indexPath.row];
	}
	else
		movie = [_movies objectAtIndex:indexPath.row];

	if(!movie.valid)
		return;

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] delMovie: movie];
	if(result.result)
	{
		[_movies removeObject:movie];
		if(_sortTitle)
		{
			NSString *key = [_currentKeys objectAtIndex:indexPath.section];
			NSArray *object = (NSArray *)[_characters valueForKey:key];
			// act like this is an mutable array and if not, create one
			// NOTE: this might be ugly, but the alternative is to recreate a possibly very long list or to preemptively create
			// mutable copys and keep them instead of the immutable ones which would be a lot overhead in most cases, so instead
			// we use this little bug ugly piece of code as a compromise
			@try
			{
				[(NSMutableArray *)object removeObjectAtIndex:indexPath.row];
			}
			@catch(NSException *exception)
			{
				NSString *exceptionName = [exception name];
				if([exceptionName isEqualToString:NSInternalInconsistencyException] || [exceptionName isEqualToString:NSInvalidArgumentException])
				{
					NSMutableArray *newObject = [object mutableCopy];
					[_characters setValue:newObject forKey:key];
					[newObject removeObjectAtIndex:indexPath.row];
					[newObject release];
				}
				else
				{
#if IS_DEBUG()
					NSLog(@"%@", exceptionName);
					@throw exception;
#else
					// alert user if movie could not be deleted
					const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																		  message:[NSString stringWithFormat:NSLocalizedString(@"An unexpected error (%@) occured after removing the recording.\nPlease reload the list manually to see the change!", @""), exceptionName]
																		 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
					[alert show];
					[alert release];
					return; // do NOT call deleteRowsAtIndexPaths
#endif
				}
			}
		}

		[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
	}
	else
	{
		// alert user if movie could not be deleted
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:result.resulttext
														delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -
#if IS_FULL()

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

#endif
#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
#pragma mark -
#if IS_FULL()

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[_filteredMovies removeAllObjects];
	const BOOL caseInsensitive = [searchString isEqualToString:[searchString lowercaseString]];
	NSStringCompareOptions options = caseInsensitive ? (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) : 0;
	for(NSObject<MovieProtocol> *movie in _movies)
	{
		NSRange range = [movie.title rangeOfString:searchString options:options];
		if(range.length)
			[_filteredMovies addObject:movie];
	}
	self.sortTitle = _sortTitle; // in case of alphabetized list

    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
	// refresh the list
	if(_sortTitle)
	{
		[self setSortTitle:YES allowSearch:NO];
		[_tableView reloadData];
	}
}

#endif
#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	self.navigationItem.leftBarButtonItem = barButtonItem;
	pc.contentViewController = aViewController;
	self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	self.navigationItem.leftBarButtonItem = nil;
	self.popoverController = nil;
}

@end
