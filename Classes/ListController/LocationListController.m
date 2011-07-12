//
//  LocationListController.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "LocationListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "Objects/LocationProtocol.h"
#import "UITableViewCell+EasyInit.h"

#import "Objects/Generic/Location.h"

@interface LocationListController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation LocationListController

@synthesize isSplit = _isSplit;
@synthesize movieListController = _movieListController;
@synthesize showDefault = _showDefault;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Locations", @"Title of LocationListController");
		_locations = [[NSMutableArray array] retain];
		_refreshLocations = YES;
		_isSplit = NO;
		_movieListController = nil;
		_delegate = nil;

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
		{
			self.contentSizeForViewInPopover = CGSizeMake(370.0f, 450.0f);
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_locations release];
	[_movieListController release];
	[_locationXMLDoc release];
	[_delegate release];

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	if(!IS_IPAD())
	{
		[_movieListController release];
		_movieListController = nil;
	}
	
	[super didReceiveMemoryWarning];
}

/* getter of willReapper */
- (BOOL)willReappear
{
	return !_refreshLocations;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_locations count]) _refreshLocations = !new;
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 38;
	_tableView.sectionHeaderHeight = 0;
}

/* cancel in delegate mode */
- (void)doneAction:(id)sender
{
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	if(_delegate)
	{
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				target:self action:@selector(doneAction:)];
		self.navigationItem.rightBarButtonItem = button;
		[button release];
	}
	else
		self.navigationItem.rightBarButtonItem = nil;

	// Refresh cache if we have a cleared one
	if(_refreshLocations && !_reloading)
	{
		[self emptyData];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];

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

	_refreshLocations = YES;

	[super viewWillAppear: animated];
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// Clean caches if supposed to
	if(_refreshLocations)
	{
		[_locations removeAllObjects];

		if(!IS_IPAD())
		{
			[_movieListController release];
			_movieListController = nil;
		}
		[_locationXMLDoc release];
		_locationXMLDoc = nil;
	}
}

/* fetch contents */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_locationXMLDoc release];
	_reloading = YES;
	_locationXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchLocationlist: self] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean location list
	[_locations removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	[_locationXMLDoc release];
	_locationXMLDoc = nil;
}

/* force a refresh */
- (void)forceRefresh
{
	[_locations removeAllObjects];
	[_tableView reloadData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	// Spawn a thread to fetch the service data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	_refreshLocations = NO;
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
			// received 404, assume very old enigma2 without location support: insert default location (if not showing anyway)
			if(!_showDefault)
			{
				GenericLocation *location = [[GenericLocation alloc] init];
				location.fullpath = @"/hdd/movie/";
				location.valid = YES;
				[self addLocation:location];
				[location release];
			}
			error = nil;
		}
	}

	// assume details will fail too if in split
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
}

#pragma mark -
#pragma mark LocationSourceDelegate
#pragma mark -

/* add location to list */
- (void)addLocation: (NSObject<LocationProtocol> *)location
{
	[_locations addObject: location];
#if INCLUDE_FEATURE(Extra_Animation)
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_locations count]-1 inSection:0]]
					  withRowAnimation: UITableViewRowAnimationTop];
#endif
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
	NSInteger row = indexPath.row;

	if(_showDefault && row-- == 0)
	{
		TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Default Location", @"");;
		return cell;
	}

	TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	TABLEVIEWCELL_TEXT(cell) = ((NSObject<LocationProtocol> *)[_locations objectAtIndex:row]).fullpath;

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	NSObject<LocationProtocol> *location = nil;
	if(_showDefault) --row;
	if(row > -1)
	{
		location = [_locations objectAtIndex:row];
		if(!location.valid)
			return nil;
	}

	// Callback mode
	if(_delegate != nil)
	{
		[_delegate performSelector:@selector(locationSelected:) withObject: location];

		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else
			[self.navigationController popToViewController: (UIViewController *)_delegate animated: YES];
	}
	// Open movie list
	else if(!_movieListController.reloading)
	{
		// Check for cached MovieListController instance
		if(_movieListController == nil)
			_movieListController = [[MovieListController alloc] init];
		_movieListController.currentLocation = location.fullpath;

		// We do not want to refresh bouquet list when we return
		_refreshLocations = NO;

		// when in split view go back to movie list, else push it on the stack
		if(!_isSplit)
		{
			// XXX: wtf?
			if([self.navigationController.viewControllers containsObject:_movieListController])
			{
#if IS_DEBUG()
				NSMutableString* result = [[NSMutableString alloc] init];
				for(NSObject* obj in self.navigationController.viewControllers)
					[result appendString:[obj description]];
				[NSException raise:@"MovieListTwiceInNavigationStack" format:@"_movieListController was twice in navigation stack: %@", result];
				[result release]; // never reached, but to keep me from going crazy :)
#endif
				[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
			}
			[self.navigationController pushViewController: _movieListController animated:YES];
		}
		else
			[_movieListController.navigationController popToRootViewControllerAnimated: YES];
	}
	else
		return nil;
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
	NSUInteger count = _locations.count;
	if(_showDefault)
		++count;
	return count;
}

/* set delegate */
- (void)setDelegate: (id<LocationListDelegate, NSCoding>) delegate
{
	[_delegate release];
	_delegate = [delegate retain];
}

/* support rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
