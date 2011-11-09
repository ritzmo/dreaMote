//
//  MovieTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "MovieTableViewCell.h"

#import "NSDateFormatter+FuzzyFormatting.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMovieCell_ID = @"MovieCell_ID";

@implementation MovieTableViewCell

@synthesize formatter;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		self.textLabel.font = [UIFont boldSystemFontOfSize:kEventNameTextSize];
		self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
		
		self.detailTextLabel.font = [UIFont systemFontOfSize:kEventDetailsTextSize];
		self.detailTextLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.detailTextLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	}
	
	return self;
}

- (void)theme
{
	self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
	self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	self.detailTextLabel.textColor = [DreamoteConfiguration singleton].textColor;
	self.detailTextLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	[super theme];
}

/* getter for movie property */
- (NSObject<MovieProtocol> *)movie
{
	return _movie;
}

/* setter for movie property */
- (void)setMovie:(NSObject<MovieProtocol> *)newMovie
{
	// Abort if same movie assigned
	if(_movie == newMovie) return;
	_movie = newMovie;

	if(!newMovie.valid)
		self.accessoryType = UITableViewCellAccessoryNone;

	// Set new label contents
	self.textLabel.text = newMovie.title;
	self.detailTextLabel.text = [formatter fuzzyDate:newMovie.time];

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;

	// XXX: we should never be editing.
	// really?! 
	if (!self.editing) {
		CGRect frame;
		
		// Place the name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 7, contentRect.size.width - kRightMargin, kEventNameTextSize + 2);
		self.textLabel.frame = frame;

		// Place the time label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 30, contentRect.size.width - kRightMargin, kEventDetailsTextSize + 2);
		self.detailTextLabel.frame = frame;
	}
}

@end
