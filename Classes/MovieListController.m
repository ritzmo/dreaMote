//
//  MovieListController.m
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieListController.h"
#import "RemoteConnectorObject.h"
#import "MovieTableViewCell.h"
#import "MovieViewController.h"

@implementation MovieListController

@synthesize movies = _movies;
@synthesize refreshMovies;

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Movies", @"");
		self.movies = [NSMutableArray array];
		self.refreshMovies = YES;
	}
	return self;
}

- (void)dealloc
{
	[_movies release];
	
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	if(refreshMovies)
	{
		[_movies removeAllObjects];
		
		[self reloadData];

		// Spawn a thread to fetch the movie data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchMovies) toTarget:self withObject:nil];
	}

	refreshMovies = YES;

	[super viewWillAppear: animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	if(refreshMovies)
	{
		[_movies removeAllObjects];
		
		[self reloadData];
	}
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 48.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	
	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

- (void)fetchMovies
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[RemoteConnectorObject sharedRemoteConnector] fetchMovielist: self action:@selector(addMovie:)];
	[pool release];
}

- (void)addMovie:(id)movie
{
	if(movie != nil)
		[_movies addObject: [(Movie*)movie retain]];
	[self reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kMovieCell_ID = @"MovieCell_ID";
	
	MovieTableViewCell *cell = (MovieTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kMovieCell_ID];
	if(cell == nil)
	{
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[MovieTableViewCell alloc] initWithFrame:cellFrame reuseIdentifier:kMovieCell_ID] autorelease];
	}

	[cell setMovie: [_movies objectAtIndex:indexPath.row]];
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];
	
	Movie *movie = [self.movies objectAtIndex: indexPath.row];
	MovieViewController *movieViewController = [MovieViewController withMovie: movie];
	[[applicationDelegate navigationController] pushViewController: movieViewController animated: YES];
	
	//[movieViewController release];

	refreshMovies = NO;
	
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_movies count];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


@end
