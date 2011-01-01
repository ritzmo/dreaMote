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

@interface LocationListController()
/*!
 @brief entry point of thread which fetches locations
 */
- (void)fetchLocations;
@end

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
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_locations release];
	[_movieListController release];
	[_locationXMLDoc release];

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

/* layout */
- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 38;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// Refresh cache if we have a cleared one
	if(_refreshLocations)
	{
		[_locations removeAllObjects];

		[(UITableView *)self.view reloadData];
		[_locationXMLDoc release];
		_locationXMLDoc = nil;

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchLocations) toTarget:self withObject:nil];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
		[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:YES];
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
- (void)fetchLocations
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_locationXMLDoc release];
	_locationXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchLocationlist: self] retain];
	[pool release];
}

/* add location to list */
- (void)addLocation: (NSObject<LocationProtocol> *)location
{
	if(location != nil)
	{
		[_locations addObject: location];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_locations count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
		[(UITableView *)self.view reloadData];
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

	// Check for cached MovieListController instance
	if(_movieListController == nil)
		_movieListController = [[MovieListController alloc] init];
	_movieListController.currentLocation = location.fullpath;

	// We do not want to refresh bouquet list when we return
	_refreshLocations = NO;

	if(!_isSplit)
		[self.navigationController pushViewController: _movieListController animated:YES];
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

/* support rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
