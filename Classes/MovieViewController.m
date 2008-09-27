//
//  MovieViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieViewController.h"

#import "CellTextView.h"
#import "CellTextField.h"
#import "DisplayCell.h"
#import "SourceCell.h"
#import "RemoteConnectorObject.h"
#import "TimerViewController.h"
#import "Constants.h"

#import "FuzzyDateFormatter.h"

@implementation MovieViewController

@synthesize movie = _movie;
@synthesize myTableView;

- (id)init
{
	if (self = [super init])
	{
		self.movie = nil;
		self.title = NSLocalizedString(@"Movie", @"Default title of MovieViewController");
	}
	
	return self;
}

+ (MovieViewController *)withMovie: (Movie *) newMovie
{
	MovieViewController *movieViewController = [[MovieViewController alloc] init];

	movieViewController.movie = newMovie;
	movieViewController.title = [newMovie title];
	
	return movieViewController;
}

- (void)dealloc
{
	[_movie release];

	[super dealloc];
}

+ (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title
{
	UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	
	label.textAlignment = UITextAlignmentLeft;
	label.text = title;
	label.font = [UIFont boldSystemFontOfSize:17.0];
	label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
	label.backgroundColor = [UIColor clearColor];

	return label;
}

- (void)loadView
{
	// create and configure the table view
	myTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	myTableView.delegate = self;
	myTableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = myTableView;
}

- (void)playAction: (id)sender
{
	Service *movieService = [[Service alloc] init];
	[movieService setSref: _movie.sref];

	[[RemoteConnectorObject sharedRemoteConnector] zapTo: movieService];
	
	[movieService release];
}

- (UITextView *)create_Summary
{
	CGRect frame = CGRectMake(0, 0, 100, kTextViewHeight);
	UITextView *myTextView = [[[UITextView alloc] initWithFrame:frame] autorelease];
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.delegate = self;
	myTextView.editable = NO;
	myTextView.backgroundColor = [UIColor whiteColor];
	
	// We display short description (or title) and extended description (if available) in our textview
	NSMutableString *text;
	if(!([[RemoteConnectorObject sharedRemoteConnector] getFeatures] & kFeaturesExtendedRecordInfo))
		text = [_movie.title copy];
	else
	{
		text = [[NSMutableString alloc] init];
		if([_movie.sdescription length])
		{
			[text appendString: _movie.sdescription];
		}
		else
		{
			[text appendString: _movie.title];
		}

		if([_movie.edescription length])
		{
			[text appendString: @"\n\n"];
			[text appendString: _movie.edescription];
		}
	}
	myTextView.text = text;
	
	[text release];
	
	return myTextView;
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	// Date Formatter
	FuzzyDateFormatter *format = [[[FuzzyDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	
	return [format stringFromDate: dateTime];
}

- (UIButton *)create_PlayButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd]; // XXX: we need a proper play icon here
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

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

#pragma mark UITextView delegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// we don't allow editing
}

- (void)saveAction:(id)sender
{
	// we don't allow editing
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(!([[RemoteConnectorObject sharedRemoteConnector] getFeatures] & kFeaturesExtendedRecordInfo))
		return 2;

	if([_movie.length integerValue] != -1)
		return 7;
	return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return NSLocalizedString(@"Description", @"");
		case 1:
			if(!([[RemoteConnectorObject sharedRemoteConnector] getFeatures] & kFeaturesExtendedRecordInfo))
				return nil;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 3)
	{
		NSUInteger count = [_movie.tags count];
		if(!count)
			return 1;
		return count;
	}
	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result;

	switch (indexPath.section)
	{
		case 0:
		{
			result = kTextViewHeight;
			break;
		}
		case 1:
			if(!([[RemoteConnectorObject sharedRemoteConnector] getFeatures] & kFeaturesExtendedRecordInfo))
			{
				result = kUIRowHeight;
				break;
			}
		case 2:
		case 3:
		case 4:
		{
			result = kTextFieldHeight;
			break;
		}
		case 5:
			if([_movie.length integerValue] != -1)
			{
				result = kTextFieldHeight;
				break;
			}
		case 6:
		{
			result = kUIRowHeight;
			break;
		}
	}
	return result;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(NSInteger)section
{
	UITableViewCell *cell = nil;

	switch (section) {
		case 0:
			cell = [myTableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
			if(cell == nil)
				cell = [[[CellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextView_ID] autorelease];
			break;
		case 1:
			if(!([[RemoteConnectorObject sharedRemoteConnector] getFeatures] & kFeaturesExtendedRecordInfo))
			{
				cell = [myTableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
				if(cell == nil)
					cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
				break;
			}
		case 2:
		case 3:
		case 4:
			cell = [myTableView dequeueReusableCellWithIdentifier:kSourceCell_ID];
			if(cell == nil)
				cell = [[[SourceCell alloc] initWithFrame:CGRectZero reuseIdentifier:kSourceCell_ID] autorelease];
			break;
		case 5:
			if([_movie.length integerValue] != -1)
			{
				cell = [myTableView dequeueReusableCellWithIdentifier:kSourceCell_ID];
				if(cell == nil)
					cell = [[[SourceCell alloc] initWithFrame:CGRectZero reuseIdentifier:kSourceCell_ID] autorelease];
				break;
			}
		case 6:
			cell = [myTableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
			break;
		default:
			break;
	}

	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = [self obtainTableCellForSection: section];

	// we are creating a new cell, setup its attributes
	switch (section) {
		case 0:
			((CellTextView *)sourceCell).view = [self create_Summary];
			break;
		case 1:
			if(!([[RemoteConnectorObject sharedRemoteConnector] getFeatures] & kFeaturesExtendedRecordInfo))
			{
				((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Play", @"");
				((DisplayCell *)sourceCell).view = [self create_PlayButton];
				break;
			}
			((SourceCell *)sourceCell).sourceLabel.text = _movie.sname;
			break;
		case 2:
			if([_movie.size integerValue] != -1)
				((SourceCell *)sourceCell).sourceLabel.text = [self format_size: _movie.size];
			else
				((SourceCell *)sourceCell).sourceLabel.text = NSLocalizedString(@"N/A", @"");
			break;
		case 3:
			if(![_movie.tags count])
				((SourceCell *)sourceCell).sourceLabel.text = NSLocalizedString(@"None", @"");
			else
				((SourceCell *)sourceCell).sourceLabel.text = [_movie.tags objectAtIndex: indexPath.row];
			break;
		case 4:
			((SourceCell *)sourceCell).sourceLabel.text = [self format_BeginEnd: _movie.time];
			break;
		case 5:
			if([_movie.length integerValue] != -1)
			{
				((SourceCell *)sourceCell).sourceLabel.text = [self format_BeginEnd: [_movie.time addTimeInterval: (NSTimeInterval)[_movie.length integerValue]]];
				break;
			}
		case 6:
			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Play", @"");
			((DisplayCell *)sourceCell).view = [self create_PlayButton];
		default:
			break;
	}
	
	return sourceCell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
