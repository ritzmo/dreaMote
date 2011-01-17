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

@implementation LocationListController

@synthesize movieListController = _movieListController;
@synthesize isSplit = _isSplit;

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

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// Refresh cache if we have a cleared one
	if(_refreshLocations)
	{
		[_locations removeAllObjects];

		[_tableView reloadData];
		[_locationXMLDoc release];
		_locationXMLDoc = nil;

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
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_locationXMLDoc release];
	_locationXMLDoc = nil;
}

/* force a refresh */
- (void)forceRefresh
{
	[_locations removeAllObjects];
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
	if(location != nil)
	{
		[_locations addObject: location];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_locations count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
#endif
	}
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if(cell == nil)
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

	TABLEVIEWCELL_FONT(cell) = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	TABLEVIEWCELL_TEXT(cell) = ((NSObject<LocationProtocol> *)[_locations objectAtIndex:indexPath.row]).fullpath;

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// See if we have a valid location
	NSObject<LocationProtocol> *location = [_locations objectAtIndex: indexPath.row];
	if(!location.valid)
		return nil;
	// Callback mode
	else if(_delegate != nil)
	{
		[_delegate performSelector:@selector(locationSelected:) withObject: location];

		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else
			[self.navigationController popToViewController: (UIViewController *)_delegate animated: YES];
	}
	// Open movie list
	else
	{
		// Check for cached MovieListController instance
		if(_movieListController == nil)
			_movieListController = [[MovieListController alloc] init];
		_movieListController.currentLocation = location.fullpath;

		// We do not want to refresh bouquet list when we return
		_refreshLocations = NO;

		// when in split view go back to movie list, else push it on the stack
		if(!_isSplit)
			[self.navigationController pushViewController: _movieListController animated:YES];
		else
			[_movieListController.navigationController popToRootViewControllerAnimated: YES];
	}
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
	return [_locations count];
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
