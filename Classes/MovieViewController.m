//
//  MovieViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "MovieViewController.h"

#import "RemoteConnectorObject.h"
#import "TimerViewController.h"
#import "Constants.h"
#import "FuzzyDateFormatter.h"

#import "CellTextView.h"
#import "DisplayCell.h"

@interface MovieViewController()
- (UITextView *)create_Summary;
@end

@implementation MovieViewController

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Movie", @"Default title of MovieViewController");
		_movie = nil;
	}
	
	return self;
}

+ (MovieViewController *)withMovie: (NSObject<MovieProtocol> *) newMovie
{
	MovieViewController *movieViewController = [[MovieViewController alloc] init];

	movieViewController.movie = newMovie;

	return [movieViewController autorelease];
}

- (void)dealloc
{
	[_movie release];
	[_summaryView release];

	[super dealloc];
}

- (NSObject<MovieProtocol> *)movie
{
	return _movie;
}

- (void)setMovie: (NSObject<MovieProtocol> *)newMovie
{
	if(_movie != newMovie)
	{
		[_movie release];
		_movie = [newMovie retain];
	}

	if(newMovie != nil)
		self.title = newMovie.title;

	[_summaryView release];
	_summaryView = [[self create_Summary] retain];

	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view
						scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:0 inSection:0]
						atScrollPosition: UITableViewScrollPositionTop
						animated: NO];
}

- (void)loadView
{
	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.sectionFooterHeight = 1;
	tableView.sectionHeaderHeight = 1;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

//* Start playback of the movie on the remote box
//* @see #zapTo:
- (void)playAction: (id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:6];
	[(UITableView *)self.view
						selectRowAtIndexPath: indexPath
						animated: YES
						scrollPosition: UITableViewScrollPositionNone];

	[[RemoteConnectorObject sharedRemoteConnector] playMovie: _movie];

	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];
}

- (UITextView *)create_Summary
{
	UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.editable = NO;

	// We display short description (or title) and extended description (if available)
	// in our textview
	NSMutableString *text;
	if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesExtendedRecordInfo])
		text = [_movie.title copy];
	else
	{
		text = [[NSMutableString alloc] init];
		if([_movie.sdescription length])
			[text appendString: _movie.sdescription];
		else
			[text appendString: _movie.title];

		if([_movie.edescription length])
		{
			[text appendString: @"\n\n"];
			[text appendString: _movie.edescription];
		}
	}
	myTextView.text = text;

	[text release];

	return [myTextView autorelease];
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	// Date Formatter
	const FuzzyDateFormatter *format = [[[FuzzyDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	
	return [format stringFromDate: dateTime];
}

- (UIButton *)create_PlayButton
{
	const CGRect frame = CGRectMake(0, 0, kUIRowHeight, kUIRowHeight);
	UIButton *button = [[UIButton alloc] initWithFrame: frame];
	UIImage *image = [UIImage imageNamed:@"media-playback-start.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(playAction:)
				forControlEvents:UIControlEventTouchUpInside];

	return [button autorelease];
}

//* Convert the size in bytes of a movie to a human-readable size
//* @param size NSNumber containing size in bytes
- (NSString *)format_size: (NSNumber*)size
{
	float floatSize = [size floatValue];

	if (floatSize < 1023)
		return [NSString stringWithFormat: @"%i bytes", floatSize];
	floatSize /= 1024;

	if (floatSize < 1023)
		return [NSString stringWithFormat: @"%1.1f KB", floatSize];
	floatSize /= 1024;

	if (floatSize < 1023)
		return [NSString stringWithFormat: @"%1.1f MB", floatSize];
	floatSize /= 1024;

	return [NSString stringWithFormat: @"%1.1f GB", floatSize];
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// FIXME: this is kinda hackish
	const UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	@try {
		[((UIControl *)((DisplayCell *)cell).view) sendActionsForControlEvents: UIControlEventTouchUpInside];
	}
	@catch (NSException * e) {
		//
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// We always have 7 sections, but not all of them have content
	return 7;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// First section is always present
	if(section == 0)
		return NSLocalizedString(@"Description", @"");

	// Other rows might be displayed if we have extended record description
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesExtendedRecordInfo])
	{
		switch(section)
		{
			case 1:
				return NSLocalizedString(@"Service", @"");
			case 2:
				return NSLocalizedString(@"Size", @"");
			case 3:
				return NSLocalizedString(@"Tags", @"");
			case 4:
				return NSLocalizedString(@"Begin", @"");
			case 5:
				if([_movie.length integerValue] != -1)
					return NSLocalizedString(@"End", @"");
			default:
				return nil;
		}
	}
	
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSUInteger count = 0;

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesExtendedRecordInfo])
	{
		/*
		 * If we have extended record descriptions we show most of the rows (unless movie length
		 * is unknown in this case its hidden) and the only section which can have more than one
		 * row is section 3 (movie tags).
		 */
		switch(section)
		{
			case 3:
				count = [_movie.tags count];
				if(!count)
					return 1;
				return count;
			case 5:
				if([_movie.length integerValue] != -1)
					return 1;
				return 0;
			default:
				return 1;
		}
	}
	else
	{
		// Only section 0 and 6 are displayed when we only have basic information.
		switch(section)
		{
			case 0:
				return 1;
			case 6:
				return 1;
			default:
				return 0;
		}
	}

	return 0;
}

// as some rows are hidden we want to hide the gap created by empty sections by
// resizing the header fields.
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(section == 0)
		return 34;

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesExtendedRecordInfo])
	{
		if(section == 5 && [_movie.length integerValue] == -1)
			return 0;
		return 34;
	}

	return 0;
}

// determine the adjustable height of a row. these are determined by the sections and if a
// section is set to be hidden the row size is reduced to 0.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	if(section == 0)
		return kTextViewHeight;
	else if(section == 6)
		return kUIRowHeight;

	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesExtendedRecordInfo])
	{
		if(section == 5 && [_movie.length integerValue] == -1)
			return 0;
		return kUIRowHeight;
	}

	return 0;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(UITableView *)tableView: (NSInteger)section
{
	UITableViewCell *cell = nil;

	switch (section) {
		case 0:
			cell = [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
			if(cell == nil)
				cell = [[[CellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextView_ID] autorelease];
			break;
		case 1:
		case 2:
		case 3:
		case 4:
		case 5:
			cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (cell == nil) 
				cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

			TABLEVIEWCELL_ALIGN(cell) = UITextAlignmentCenter;
			TABLEVIEWCELL_COLOR(cell) = [UIColor blackColor];
			TABLEVIEWCELL_FONT(cell) = [UIFont systemFontOfSize:kTextViewFontSize];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.indentationLevel = 1;
			break;
		case 6:
			cell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
		default:
			break;
	}

	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = [self obtainTableCellForSection: tableView: section];

	// we are creating a new cell, setup its attributes
	switch (section) {
		case 0:
			((CellTextView *)sourceCell).view = _summaryView;
			_summaryView.backgroundColor = sourceCell.backgroundColor;
			break;
		case 1:
			TABLEVIEWCELL_TEXT(sourceCell) = _movie.sname;
			break;
		case 2:
			if([_movie.size integerValue] != -1)
				TABLEVIEWCELL_TEXT(sourceCell) = [self format_size: _movie.size];
			else
				TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"N/A", @"");
			break;
		case 3:
			if(![_movie.tags count])
				TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"None", @"");
			else
				TABLEVIEWCELL_TEXT(sourceCell) = [_movie.tags objectAtIndex: indexPath.row];
			break;
		case 4:
			TABLEVIEWCELL_TEXT(sourceCell) = [self format_BeginEnd: _movie.time];
			break;
		case 5:
			TABLEVIEWCELL_TEXT(sourceCell) = [self format_BeginEnd: [_movie.time addTimeInterval: (NSTimeInterval)[_movie.length integerValue]]];
			break;
		case 6:
			sourceCell.selectionStyle = UITableViewCellSelectionStyleBlue;
			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Play", @"");
			((DisplayCell *)sourceCell).view = [self create_PlayButton];
		default:
			break;
	}
	
	return sourceCell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// We only allow to rotate "back" to our favourite orientation...
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
