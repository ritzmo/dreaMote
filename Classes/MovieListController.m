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

#import "NSDateFormatter+FuzzyFormatting.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "MovieProtocol.h"

#import "Objects/Generic/Result.h"

@interface MovieListController()
/*!
 @brief Popover Controller.
 */
@property (nonatomic, retain) UIPopoverController *popoverController;
@end

@implementation MovieListController

@synthesize popoverController;
@synthesize isSplit = _isSplit;
@synthesize movieViewController = _movieViewController;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");
		_movies = [[NSMutableArray array] retain];
		_refreshMovies = YES;
		_isSplit = NO;

		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];

		_movieViewController = nil;

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
	[_movies release];
	[_dateFormatter release];
	[_movieViewController release];
	[_movieXMLDoc release];

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
	if([_currentLocation isEqualToString: newLocation]) return;
	
	// Free old bouquet, retain new one
	[_currentLocation release];
	_currentLocation = [newLocation retain];
	
	// Set Title
	if(newLocation)
		self.title = newLocation;
	else
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");
	
	// Free Caches and reload data
	[_movies removeAllObjects];
	[_tableView reloadData];
	[_movieXMLDoc release];
	_movieXMLDoc = nil;
	_refreshMovies = NO;
	
	// Eventually remove popover
	if(self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
	
	// Spawn a thread to fetch the movie data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
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

/* memory warning */
- (void)didReceiveMemoryWarning
{
	if(!IS_IPAD())
	{
		[_movieViewController release];
		_movieViewController = nil;
	}

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
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	else
		self.navigationItem.rightBarButtonItem = nil;

	if(_refreshMovies)
	{
		[_movies removeAllObjects];

		[_tableView reloadData];
		[_movieXMLDoc release];
		_movieXMLDoc = nil;

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
		if(!IS_IPAD())
		{
			[_movieViewController release];
			_movieViewController = nil;
		}
		[_movieXMLDoc release];
		_movieXMLDoc = nil;
	}

	[_dateFormatter resetReferenceDate];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.sectionHeaderHeight = 0;
}

/* fetch movie list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_movieXMLDoc release];
	_reloading = YES;
	_movieXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchMovielist: self withLocation: _currentLocation] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_movies removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_movieXMLDoc release];
	_movieXMLDoc = nil;
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
}

#pragma mark -
#pragma mark MovieSourceDelegate methods
#pragma mark -

/* add movie to list */
- (void)addMovie: (NSObject<MovieProtocol> *)movie
{
	if(movie != nil)
	{
		const NSUInteger idx = _movies.count;
		[_movies addObject: movie];
		[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
						withRowAnimation: UITableViewRowAnimationLeft];
	}
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MovieTableViewCell *cell = (MovieTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kMovieCell_ID];
	if(cell == nil)
		cell = [[[MovieTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMovieCell_ID] autorelease];

	cell.formatter = _dateFormatter;
	cell.movie = [_movies objectAtIndex:indexPath.row];
	
	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<MovieProtocol> *movie = [_movies objectAtIndex: indexPath.row];
	if(!movie.valid)
		return nil;

	if(_movieViewController == nil)
		_movieViewController = [[MovieViewController alloc] init];
	_movieViewController.movie = movie;

	if(!_isSplit)
	{
		[self.navigationController pushViewController: _movieViewController animated: YES];
	}

	_refreshMovies = NO;

	return indexPath;
}

/* row count */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
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
	const NSInteger index = indexPath.row;
	NSObject<MovieProtocol> *movie = [_movies objectAtIndex: index];

	if(!movie.valid)
		return;

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] delMovie: movie];
	if(result.result)
	{

		[_movies removeObjectAtIndex: index];
			
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
								withRowAnimation: UITableViewRowAnimationFade];
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
#pragma mark Split view support
#pragma mark -

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	self.navigationItem.leftBarButtonItem = barButtonItem;
	pc.contentViewController = aViewController;
	self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	self.navigationItem.leftBarButtonItem = nil;
	self.popoverController = nil;
}

@end
