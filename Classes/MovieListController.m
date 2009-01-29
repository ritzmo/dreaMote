//
//  MovieListController.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieListController.h"

#import "MovieTableViewCell.h"
#import "MovieViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"
#import "FuzzyDateFormatter.h"

#import "MovieProtocol.h"

@implementation MovieListController

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Movies", @"Title of MovieListController");
		_movies = [[NSMutableArray array] retain];
		refreshMovies = YES;

		dateFormatter = [[FuzzyDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];

		movieViewController = nil;
	}
	return self;
}

- (void)dealloc
{
	[_movies release];
	[dateFormatter release];
	[movieViewController release];
	[movieXMLDoc release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[movieViewController release];
	movieViewController = nil;

    [super didReceiveMemoryWarning];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];
	[(UITableView*)self.view setEditing: editing animated: animated];
}

- (void)viewWillAppear:(BOOL)animated
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordDelete])
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	else
		self.navigationItem.rightBarButtonItem = nil;

	if(refreshMovies)
	{
		[_movies removeAllObjects];

		[(UITableView *)self.view reloadData];
		[movieXMLDoc release];
		movieXMLDoc = nil;

		// Spawn a thread to fetch the movie data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchMovies) toTarget:self withObject:nil];
	}

	refreshMovies = YES;

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// XXX: I'd actually do this in background (e.g. viewDidDisappear) but this
	// wouldn't reset the editButtonItem
	if(self.editing)
		[self setEditing:NO animated: YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
	if(refreshMovies)
	{
		[_movies removeAllObjects];
		[movieViewController release];
		movieViewController = nil;
		[movieXMLDoc release];
		movieXMLDoc = nil;
	}

	[dateFormatter resetReferenceDate];
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

- (void)fetchMovies
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[movieXMLDoc release];
	movieXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchMovielist: self action:@selector(addMovie:)] retain];
	[pool release];
}

- (void)addMovie:(NSObject<MovieProtocol> *)movie
{
	if(movie != nil)
	{
		[_movies addObject: movie];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_movies count]-1 inSection:0]]
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MovieTableViewCell *cell = (MovieTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kMovieCell_ID];
	if(cell == nil)
		cell = [[[MovieTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMovieCell_ID] autorelease];

	cell.formatter = dateFormatter;
	cell.movie = [_movies objectAtIndex:indexPath.row];
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<MovieProtocol> *movie = [_movies objectAtIndex: indexPath.row];
	if(!movie.valid)
		return nil;

	if(movieViewController == nil)
		movieViewController = [[MovieViewController alloc] init];
	movieViewController.movie = movie;

	[self.navigationController pushViewController: movieViewController animated: YES];

	refreshMovies = NO;

	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_movies count];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{	
	NSInteger index = indexPath.row;

	NSObject<MovieProtocol> *movie = [_movies objectAtIndex: index];
	if(!movie.valid)
		return;

	if([[RemoteConnectorObject sharedRemoteConnector] delMovie: movie])
	{

		[_movies removeObjectAtIndex: index];
			
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
								withRowAnimation: UITableViewRowAnimationFade];
	}
	else
	{
		// alert user if movie could not be deleted
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:nil
														delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
