//
//  MovieListController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "MovieListController.h"

#import <TableViewCell/MovieTableViewCell.h>
#import <ListController/ServiceZapListController.h>
#import <ListController/SimpleMultiSelectionListController.h>
#import <ViewController/MovieViewController.h>

#import "Constants.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"
#import "UIDevice+SystemVersion.h"

#import <Objects/MovieProtocol.h>
#import <Objects/Generic/Result.h>

#import "MBProgressHUD.h"

#define deleteExtraWidth	35

@interface MovieListController()
- (void)setSortTitle:(BOOL)newSortTitle allowSearch:(BOOL)allowSearch;
- (void)updateButtons;
- (void)setupToolbar;
- (void)setupLeftBarButton;

/*!
 @brief Open Tag selection.
 */
- (void)tags:(id)sender;

/*!
 @brief Multi-Delete from Playlist.

 @param sender Unused parameter required by Buttons.
 */
- (IBAction)multiDelete:(id)sender;

/*!
 @brief Long press gesture was issued.
 */
- (void)zapAction:(UILongPressGestureRecognizer *)gesture inView:(UITableView *)tableView;

- (void)longPressInMainTable:(UILongPressGestureRecognizer *)gesture;
- (void)longPressInSearchTable:(UILongPressGestureRecognizer *)gesture;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIBarButtonItem *popoverButtonItem;
@property (nonatomic, strong) UIPopoverController *tagPopoverController;
@property (nonatomic, assign) BOOL sortTitle;

/*!
 @brief Tags of current movies.
 */
@property (nonatomic, strong) NSMutableSet *allTags;

/*!
 @brief List of currently selected tags.
 @note Must be nil if no tags selected!
 */
@property (nonatomic, strong) NSSet *selectedTags;

/*!
 @brief List of movies with the currently selected Tags.
 @note Can be nil if not used to spare some ressources.
 */
@property (nonatomic, strong) NSMutableArray *taggedMovies;

/*!
 @brief Activity Indicator.
 */
@property (nonatomic, strong) MBProgressHUD *progressHUD;

/*!
 @brief Zap type selection.
 */
@property (nonatomic, strong) ServiceZapListController *zapListController;
@property (nonatomic, strong) UIPopoverController *popoverZapController;
@end

@implementation MovieListController

@synthesize allTags, popoverButtonItem, popoverController, progressHUD, isSplit;
@synthesize isSlave, selectedTags, taggedMovies, tagPopoverController;
@synthesize zapListController, popoverZapController;
#if IS_FULL()
@synthesize searchBar;
#endif

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");
		allTags = [[NSMutableSet alloc] init];
		_movies = [[NSMutableArray alloc] init];
		_selected = [[NSMutableSet alloc] init];
		_characters = [[NSMutableDictionary alloc] init];
#if IS_FULL()
		_filteredMovies = [[NSMutableArray alloc] init];
#endif
		_refreshMovies = YES;

		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];

		NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
		_sortTitle = [stdDefaults boolForKey:kSortMoviesByTitle];

		self.contentSizeForViewInPopover = CGSizeMake(370.0f, 600.0f);
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.movieViewController = nil;
#if IS_FULL()
	_tableView.tableHeaderView = nil; // references searchBar
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
#endif
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
	_currentLocation = newLocation;

	// Set Title
	if(newLocation)
		self.title = newLocation;
	else
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");

	// Free Caches and reload data
	selectedTags = nil;
	_tagButton.title = NSLocalizedString(@"Tags", @"");
	taggedMovies = nil;
	_reloading = YES;
	[self emptyData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
	CGFloat topOffset = -_tableView.contentInset.top;
	if(IS_IPHONE() && [UIDevice olderThanIos:5.0f])
		topOffset += searchBar.frame.size.height;
	[_tableView setContentOffset:CGPointMake(0, topOffset) animated:YES];
#endif

	// Eventually remove popover
	if(self.popoverController != nil) {
		[self.popoverController dismissPopoverAnimated:YES];
	}

	_refreshMovies = NO;
	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
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
		_movieViewController = new;
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
	if(!editing) // clear once when switching editing off
	{
		[_selected removeAllObjects];
		[self updateButtons];
	}
	[super setEditing: editing animated: animated];
	[_tableView setEditing: editing animated: animated];
	if(animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2f];
	}
	[self setupToolbar];
	if(animated)
		[UIView commitAnimations];
	if(IS_IPAD())
		[self.navigationController setToolbarHidden:!editing animated:animated];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	const BOOL isIpad = IS_IPAD();
	if(isIpad)
		[self setupLeftBarButton];

	[self setupToolbar];

	if(_refreshMovies && !_reloading)
	{
		_reloading = YES;
		[self emptyData];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
		[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
#endif

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
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
		[taggedMovies removeAllObjects];
		if(IS_IPHONE())
			self.movieViewController = nil;
		_xmlReader = nil;
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
		_currentLocation = nil;
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
	else
#endif
	if(selectedTags) movies = taggedMovies;
	if(!movies.count)
	{
		[_characters removeAllObjects];
		_currentKeys = nil;
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

		_currentKeys = [[_characters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	else
	{
		[_characters removeAllObjects];
		_currentKeys = nil;
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

- (void)multiDeleteDefer
{
	NSMutableString *errorMessages = [[NSMutableString alloc] init];
	NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
	dispatch_block_t mainBlock = nil;

	NSSet *set = [_selected copy];
	float countPerMovie = 1/(float)[set count];
	for(NSObject<MovieProtocol> *movie in set)
	{
		Result *result = [sharedRemoteConnector delMovie: movie];
		if(result.result)
		{
			[_movies removeObject:movie];
			if(selectedTags && [taggedMovies containsObject:movie])
				[taggedMovies removeObject:movie];
		}
		else
			[errorMessages appendFormat:@"\n%@", result.resulttext];
		progressHUD.progress += countPerMovie;
	}
	if(errorMessages.length)
	{
		// alert user if movie could not be deleted
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:errorMessages
															 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		mainBlock = ^{
			[progressHUD hide:YES];
			[alert show];
		};
	}
	else
	{
		progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		progressHUD.mode = MBProgressHUDModeCustomView;
		progressHUD.labelText = NSLocalizedString(@"Movies deleted", @"Text of HUD when multiple movies were removed");
		mainBlock = ^{
			[progressHUD hide:YES afterDelay:2];
		};
	}

	// resort current table view if sorting by title
	if(_sortTitle)
		[self setSortTitle:YES allowSearch:YES];
	UITableView *tableView = _tableView;
#if IS_FULL()
	// reload active table view
	if(_searchDisplay.active)
		tableView = _searchDisplay.searchResultsTableView;
#endif
	dispatch_async(dispatch_get_main_queue(), ^{
		[tableView reloadData];
		mainBlock();
	});
}

- (void)multiDelete:(id)sender
{
	[popoverController dismissPopoverAnimated:YES];
	self.popoverController = nil;

	progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:progressHUD];
	progressHUD.delegate = self;
	[progressHUD setLabelText:NSLocalizedString(@"Deleting", @"Label of Progress HUD in MovieList when deleting multiple items")];
	[progressHUD setMode:MBProgressHUDModeDeterminate];
	progressHUD.progress = 0.0f;
	[progressHUD show:YES];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[self multiDeleteDefer];
	});

	NSString *text = NSLocalizedString(@"Delete", @"Delete button in MovieList");
	CGSize textSize = [text sizeWithFont:_deleteButton.titleLabel.font];
	[_deleteButton setTitle:text forState:UIControlStateNormal];
	_deleteButton.frame = CGRectMake(0, 0, textSize.width + deleteExtraWidth, 33);
	_deleteButton.enabled = NO;
}

- (void)tags:(id)sender
{
	SimpleMultiSelectionListController *vc = [SimpleMultiSelectionListController withItems:[allTags sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(caseInsensitiveCompare:)]]]
																			  andSelection:selectedTags
																				  andTitle:NSLocalizedString(@"Select Tags", @"")];

	const BOOL isIpad = IS_IPAD();
	vc.callback = ^(NSSet *newSelectedItems, BOOL cancel)
	{
		if(!cancel)
		{
			if(newSelectedItems.count)
			{
				selectedTags = newSelectedItems;
				taggedMovies = [[NSMutableArray alloc] init];
				for(NSObject<MovieProtocol> *movie in _movies)
				{
					if([selectedTags isSubsetOfSet:[NSSet setWithArray:movie.tags]])
						[taggedMovies addObject:movie];
				}
#if IS_FULL()
				if(_searchDisplay.isActive)
					[self searchDisplayController:_searchDisplay shouldReloadTableForSearchString:_searchDisplay.searchBar.text];
#endif
				_tagButton.title = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Tags", @""), newSelectedItems.count];
			}
			else
			{
				_tagButton.title = NSLocalizedString(@"Tags", @"");
				selectedTags = nil;
				taggedMovies = nil;
			}
			UITableView *tableView = _tableView;
#if IS_FULL()
			if(_searchDisplay.isActive) tableView = _searchDisplay.searchResultsTableView;
#endif
			[tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		}

		if(isIpad)
		{
			[tagPopoverController dismissPopoverAnimated:YES];
			tagPopoverController = nil;
		}
		else
			[self.navigationController popToViewController:self animated:YES];
	};

	if(isIpad)
	{
		// hide popover if already visible
		if([tagPopoverController isPopoverVisible])
		{
			[tagPopoverController dismissPopoverAnimated:YES];
			tagPopoverController = nil;
			return;
		}

		tagPopoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
		[tagPopoverController presentPopoverFromBarButtonItem:sender
									 permittedArrowDirections:UIPopoverArrowDirectionUp
													 animated:YES];
	}
	else
		[self.navigationController pushViewController:vc animated:YES];
}

- (void)updateButtons
{
	NSUInteger count = _selected.count;
	NSString *text = nil;
	if(count)
	{
		text = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Delete", @"Delete button in MediaPlayer"), count];
		_deleteButton.enabled = YES;
	}
	else
	{
		text = NSLocalizedString(@"Delete", @"Delete button in MovieList");
		_deleteButton.enabled = NO;
	}
	CGSize textSize = [text sizeWithFont:_deleteButton.titleLabel.font];
	[_deleteButton setTitle:text forState:UIControlStateNormal];
	if(_deleteButton.frame.size.width != textSize.width + deleteExtraWidth)
		_deleteButton.frame = CGRectMake(0, 0, textSize.width + deleteExtraWidth, 33);
}

- (void)setupToolbar
{
	const BOOL isIpad = IS_IPAD();
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordDelete])
	{
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																						target:nil
																						action:nil];
		NSArray *items = nil;

		if(isIpad)
		{
			// iOS 5.0+
			if([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)])
			{
				items = [[NSArray alloc] initWithObjects:self.editButtonItem, _sortButton, nil];
				self.navigationItem.rightBarButtonItems = items;
			}
			else
			{
				UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 190, self.navigationController.navigationBar.frame.size.height)];
				items = [[NSArray alloc] initWithObjects:flexItem, _sortButton, self.editButtonItem, nil];
				[toolbar setItems:items animated:NO];
				UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

				self.navigationItem.rightBarButtonItem = buttonItem;
			}
		}
		else
		{
			if(self.editing)
			{
				UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithCustomView:_deleteButton];
				items = [[NSArray alloc] initWithObjects:deleteItem, flexItem, self.editButtonItem, nil];
			}
			else
			{
				// NOTE: this is actually not the right place to check for this, but fixing this requires some more refactoring :)
				if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesRecordingLocations])
					items = [[NSArray alloc] initWithObjects:_tagButton, flexItem, _sortButton, flexItem, self.editButtonItem, nil];
				else
					items = [[NSArray alloc] initWithObjects:_sortButton, flexItem, self.editButtonItem, nil];
			}
			[self setToolbarItems:items animated:NO];
			[self.navigationController setToolbarHidden:NO animated:YES];

			self.navigationItem.rightBarButtonItem = nil;
		}
	}
	else
	{
		// iOS 5.0+
		if([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)])
			self.navigationItem.rightBarButtonItems = [NSArray arrayWithObject:_sortButton];
		else
			self.navigationItem.rightBarButtonItem = _sortButton;
	}
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.allowsSelectionDuringEditing = YES;

	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressInMainTable:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[_tableView addGestureRecognizer:longPressGesture];

	_sortButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleBordered target:self action:@selector(switchSort:)];
	if(_sortTitle)
		_sortButton.title = NSLocalizedString(@"Sort by time", @"Sort (movies) by time");
	else
		_sortButton.title = NSLocalizedString(@"Sort A-Z", @"Sort (movies) alphabetically");

	_deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
	_deleteButton.titleLabel.font = [UIFont systemFontOfSize:17];
	[_deleteButton setBackgroundImage:[[UIImage imageNamed:@"delete.png"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateNormal];
	[_deleteButton setImage:[UIImage imageNamed:@"trashicon.png"] forState:UIControlStateNormal];
	NSString *text = NSLocalizedString(@"Delete", @"Delete button in MovieList");
	CGSize textSize = [text sizeWithFont:_deleteButton.titleLabel.font];
	[_deleteButton setTitle:text forState:UIControlStateNormal];
	_deleteButton.frame = CGRectMake(0, 0, textSize.width + deleteExtraWidth, 33);
	[_deleteButton addTarget:self action:@selector(multiDelete:) forControlEvents:UIControlEventTouchUpInside];
	_deleteButton.enabled = NO;

	_tagButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tags", @"")
												 style:UIBarButtonItemStyleBordered
												target:self
												action:@selector(tags:)];

#if IS_FULL()
	searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.keyboardType = UIKeyboardTypeDefault;
	_tableView.tableHeaderView = searchBar;

	if(_reloading)
	{
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		CGFloat topOffset = -_tableView.contentInset.top;
		// NOTE: offset is a little off on iPad iOS 4.2, but this is the best looking version on everything else
		[_tableView setContentOffset:CGPointMake(0, topOffset) animated:YES];
	}
	else
	{
		// hide the searchbar
		[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height)];
	}

	_searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	_searchDisplay.delegate = self;
	_searchDisplay.searchResultsDataSource = self;
	_searchDisplay.searchResultsDelegate = self;
#else
	if(_reloading)
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#endif

	const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:nil];
	const UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithCustomView:_deleteButton];
	[self setToolbarItems:[NSArray arrayWithObjects:deleteItem, flexItem, nil]];

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReconnect:) name:kReconnectNotification object:nil];

	[self theme];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReconnectNotification object:nil];
	[_characters removeAllObjects];
	[_movies removeAllObjects];
	[allTags removeAllObjects];
	selectedTags = nil;
	taggedMovies = nil;
	[self setToolbarItems:nil];
	_currentKeys = nil;
	_sortButton = nil;
	SafeDestroyButton(_deleteButton);
	_tagButton = nil;
#if IS_FULL()
	[_filteredMovies removeAllObjects];
	_tableView.tableHeaderView = nil; // references searchBar
	searchBar = nil;
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	_searchDisplay = nil;
#endif

	[super viewDidUnload];
}

/* fetch movie list */
- (void)fetchData
{
	_reloading = YES;
	_sortButton.enabled = NO;
	_tagButton.enabled = NO;
	_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] fetchMovielist:self withLocation:_currentLocation];
}

/* remove content data */
- (void)emptyData
{
	// Clean movie list(s)
	[_characters removeAllObjects];
	[_movies removeAllObjects];
	[_selected removeAllObjects];
	[allTags removeAllObjects];
	[taggedMovies removeAllObjects];
	_currentKeys = nil;
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
	_xmlReader = nil;
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
		if(indexPath.row < (NSInteger)movies.count - 1)
			indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
		else if(indexPath.section < (NSInteger)_currentKeys.count - 1)
			indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
		else
			indexPath = nil;
	}
	else
	{
		NSArray *movies = _movies;
#if IS_FULL()
		if(_searchDisplay.active) movies = _filteredMovies;
		else
#endif
		if(selectedTags) movies = taggedMovies;
		if(indexPath.row < (NSInteger)[movies count] - 1)
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

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	if(isSplit)
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
		_reloading = NO;
	}
	else
	{
		[super dataSourceDelegate:dataSource errorParsingDocument:error];
	}
	_sortButton.enabled = YES;
	_tagButton.enabled = allTags.count > 0;
#if IS_FULL()
	[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height) animated:YES];
#endif
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
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
		[super dataSourceDelegateFinishedParsingDocument:dataSource];
	}
	_sortButton.enabled = YES;
	_tagButton.enabled = allTags.count > 0;
#if IS_FULL()
	[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height) animated:YES];
#endif
}

#pragma mark -
#pragma mark MovieSourceDelegate methods
#pragma mark -

/* add movie to list */
- (void)addMovie: (NSObject<MovieProtocol> *)movie
{
	[_movies addObject:movie];
	[allTags addObjectsFromArray:movie.tags];

	if(selectedTags)
	{
		for(NSString *tag in selectedTags)
		{
			if(![movie.tags containsObject:tag])
				return;
		}
		[taggedMovies addObject:movie];
	}
}

- (void)addMovies:(NSArray *)items
{
#if INCLUDE_FEATURE(Extra_Animation)
	NSUInteger count = (selectedTags) ? taggedMovies.count : _movies.count;
	NSMutableArray *indexPaths = (!_sortTitle) ? [NSMutableArray arrayWithCapacity:items.count] : nil;
#endif
	[_movies addObjectsFromArray:items];
	BOOL add = YES;
	for(NSObject<MovieProtocol> *movie in items)
	{
		[allTags addObjectsFromArray:movie.tags];
		if(selectedTags)
		{
			add = YES;
			for(NSString *tag in selectedTags)
			{
				if(![movie.tags containsObject:tag])
				{
					add = NO;
					break;
				}
			}
			if(add)
			{
				[taggedMovies addObject:movie];
#if INCLUDE_FEATURE(Extra_Animation)
				[indexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];
				++count;
#endif
			}
		}
#if INCLUDE_FEATURE(Extra_Animation)
		else
		{
			[indexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];
			++count;
		}
#endif
	}
#if INCLUDE_FEATURE(Extra_Animation)
	if(indexPaths && indexPaths.count)
		[_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
#endif
}

#pragma mark -
#pragma mark MBProgressHUDDelegate
#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[progressHUD removeFromSuperview];
	self.progressHUD = nil;
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MovieTableViewCell *cell = [MovieTableViewCell reusableTableViewCellInView:tableView withIdentifier:kMovieCell_ID];

	BOOL shouldSelect = NO;
	NSObject<MovieProtocol> *movie = nil;
	cell.formatter = _dateFormatter;
	@try
	{
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
			else
#endif
			if(selectedTags) movies = taggedMovies;
			movie = [movies objectAtIndex:indexPath.row];
		}
	}
	@catch (NSException *exception)
	{
		NSLog(@"[MovieListController] Exception while trying to assign movie to cell (%d, %d - max %d): %@", indexPath.section, indexPath.row, [_movies count], [exception description]);
#if IS_DEBUG()
		[exception raise];
#endif
	}
	@finally
	{
		cell.movie = movie;
		shouldSelect = (movie && [_selected containsObject:movie]) ? YES : NO;
		if(shouldSelect)
			[(MovieTableViewCell *)cell setMultiSelected:YES animated:NO];
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave multiSelected:shouldSelect];
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MovieTableViewCell *cell = (MovieTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	NSObject<MovieProtocol> *movie = cell.movie;
	if(!movie.valid)
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];;

	if(self.editing)
	{
		const BOOL selected = [cell toggleMultiSelected];

		if(selected)
			[_selected addObject:cell.movie];
		else
			[_selected removeObject:cell.movie];
		[self updateButtons];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else
	{
		self.movieViewController.movie = movie;

		if(!isSplit)
		{
			// XXX: wtf?
			if([self.navigationController.viewControllers containsObject:_movieViewController])
			{
#if IS_DEBUG()
				NSMutableString* result = [[NSMutableString alloc] init];
				for(NSObject* obj in self.navigationController.viewControllers)
					[result appendString:[obj description]];
				[NSException raise:@"MovieViewTwiceInNavigationStack" format:@"_movieViewController was twice in navigation stack: %@", result];
#endif
				[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
			}
			[self.navigationController pushViewController:_movieViewController animated:YES];
		}
		_refreshMovies = NO;
	}
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

/* header height */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(_sortTitle)
		return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
	return 0.0001;
}

/* section header */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_sortTitle)
		return [_currentKeys objectAtIndex:section];
	return nil;
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
	return (selectedTags) ? taggedMovies.count : _movies.count;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// allow swipe to delete and multi selection
	return (tableView.editing) ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
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
		[NSException raise:@"MovieListUserInteractionWhileReloading" format:@"commitEditingStyle was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return;
	}

	MovieTableViewCell *cell = (MovieTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	NSObject<MovieProtocol> *movie = cell.movie;

	if(!movie.valid)
		return;

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] delMovie: movie];
	if(result.result)
	{
		[_movies removeObject:movie];
		if(selectedTags)
			[taggedMovies removeObject:movie];
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
					return; // do NOT call deleteRowsAtIndexPaths
#endif
				}
			}
		}

		showCompletedHudWithText(NSLocalizedString(@"Movie deleted", @"Text of HUD when a movied was removed successfully"));

		[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
	}
	else
	{
		// alert user if movie could not be deleted
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:result.resulttext
														delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
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
	NSArray *movies = selectedTags ? taggedMovies : _movies;
	for(NSObject<MovieProtocol> *movie in movies)
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
	}
	[_tableView reloadData]; // refresh possibly changed multi selection images
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)searchTableView
{
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressInSearchTable:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[searchTableView addGestureRecognizer:longPressGesture];

	searchTableView.backgroundColor = _tableView.backgroundColor;
	searchTableView.allowsSelectionDuringEditing = YES;
	searchTableView.editing = _tableView.editing;
	searchTableView.rowHeight = _tableView.rowHeight;
	[searchTableView reloadData]; // need this reload to fix row height
}

#endif
#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)setupLeftBarButton
{
	UIBarButtonItem *tagButton = nil;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesRecordingLocations])
	{
		tagButton = _tagButton;
	}
	NSMutableArray *items;
	if(tagButton && popoverButtonItem)
	{
		items = [NSMutableArray arrayWithObjects:popoverButtonItem, tagButton, nil];
	}
	else if(tagButton)
		items = [NSMutableArray arrayWithObject:tagButton];
	else if(popoverButtonItem)
		items = [NSMutableArray arrayWithObject:popoverButtonItem];
	else
		items = [NSMutableArray array];

	// iOS 5.0+
	if([self.navigationItem respondsToSelector:@selector(leftBarButtonItems)])
	{
		self.navigationItem.leftBarButtonItems = items;
	}
	// Code for older iOS *grml*
	else if(items.count > 1)
	{
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																						target:nil
																						action:nil];
		UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 190, self.navigationController.navigationBar.frame.size.height)];
		[items addObject:flexItem];
		[toolbar setItems:items animated:NO];
		UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

		self.navigationItem.leftBarButtonItem = buttonItem;
	}
	else if(items.count)
		self.navigationItem.leftBarButtonItem = [items objectAtIndex:0];
	else
		self.navigationItem.leftBarButtonItem = nil;
}

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	[super splitViewController:svc willHideViewController:aViewController withBarButtonItem:barButtonItem forPopoverController:pc];
	self.popoverButtonItem = barButtonItem;
	self.popoverController = pc;
	[self setupLeftBarButton];
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	[super splitViewController:svc willShowViewController:aViewController invalidatingBarButtonItem:barButtonItem];
	self.popoverButtonItem = nil;
	self.popoverController = nil;
	[self setupLeftBarButton];
}

#pragma mark Zapping

- (void)longPressInMainTable:(UILongPressGestureRecognizer *)gesture
{
	[self zapAction:gesture inView:_tableView];
}

- (void)longPressInSearchTable:(UILongPressGestureRecognizer *)gesture
{
	[self zapAction:gesture inView:_searchDisplay.searchResultsTableView];
}

/* zap */
- (void)zapAction:(UILongPressGestureRecognizer *)gesture inView:(UITableView *)tableView
{
	// only do something on gesture start
	if(gesture.state != UIGestureRecognizerStateBegan)
		return;

	// get movie
	const CGPoint p = [gesture locationInView:tableView];
	NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
	MovieTableViewCell *cell = (MovieTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	NSObject<MovieProtocol> *movie = cell.movie;

	// Check for invalid movie
	if(!movie.valid)
		return;

	// if streaming supported, show popover on ipad and action sheet on iphone
	if([ServiceZapListController canStream])
	{
		zap_callback_t callback = ^(ServiceZapListController *zlc, zapAction selectedAction)
		{
			NSURL *streamingURL = nil;
			NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
			if(self.zapListController == zlc)
				self.zapListController = nil;

			if(selectedAction == zapActionRemote)
			{
				[sharedRemoteConnector playMovie:movie];
				return;
			}

			streamingURL = [sharedRemoteConnector getStreamURLForMovie:movie];
			if(!streamingURL)
			{
				// Alert user
				const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																	  message:NSLocalizedString(@"Unable to generate stream URL.", @"Failed to retrieve or generate URL of remote stream")
																	 delegate:nil
															cancelButtonTitle:@"OK"
															otherButtonTitles:nil];
				[alert show];
			}
			else
				[ServiceZapListController openStreamWithViewController:streamingURL withAction:selectedAction withViewController:self];
		};

		zapAction defaultZapAction = [[NSUserDefaults standardUserDefaults] integerForKey:kZapModeDefault];
		if(defaultZapAction != zapActionMax)
		{
			callback(nil, defaultZapAction);
		}
		else if(IS_IPAD())
		{
			// hide popover if already visible
			if([popoverController isPopoverVisible])
			{
				[popoverController dismissPopoverAnimated:YES];
			}
			if([self.popoverZapController isPopoverVisible])
			{
				[popoverZapController dismissPopoverAnimated:YES];
				self.popoverController = nil;
				return;
			}

			ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
			zlc.callback = callback;
			popoverZapController = [[UIPopoverController alloc] initWithContentViewController:zlc];

			CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
			cellRect.origin.x = p.x - 25.0f;
			cellRect.size.width = cellRect.size.width - cellRect.origin.x;
			[popoverZapController presentPopoverFromRect:cellRect
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight
												animated:YES];
		}
		else
		{
			zapListController = [ServiceZapListController showAlert:callback fromTabBar:self.tabBarController.tabBar];
		}
	}
	// else just zap on remote host
	else
	{
		[[RemoteConnectorObject sharedRemoteConnector] playMovie:movie];
	}
}

@end
