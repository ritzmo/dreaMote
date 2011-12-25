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

@synthesize formatter, movie;

/* setter for movie property */
- (void)setMovie:(NSObject<MovieProtocol> *)newMovie
{
	// Abort if same movie assigned
	if(movie == newMovie) return;
	movie = newMovie;

	if(newMovie.valid)
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if(!newMovie.timeString)
		{
			newMovie.timeString = [formatter fuzzyDate:movie.time];
		}
	}
	else
		self.accessoryType = UITableViewCellAccessoryNone;

	// Redraw
	[self setNeedsDisplay];
}

- (NSString *)accessibilityLabel
{
	return movie.title;
}

- (NSString *)accessibilityValue
{
	NSString *value = [super accessibilityValue];
	if(!value)
		return movie.timeString;
	return value;
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

- (void)drawContentRect:(CGRect)contentRect
{
	[super drawContentRect:contentRect]; // draw multi selection pixmap

	CGFloat offsetX = contentRect.origin.x + kLeftMargin;
	const CGFloat forWidth = contentRect.size.width - offsetX;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *primaryColor = nil;
	UIFont *primaryFont = [UIFont boldSystemFontOfSize:singleton.eventNameTextSize];
	UIFont *secondaryFont = [UIFont systemFontOfSize:singleton.eventDetailsTextSize];
	if(self.highlighted)
	{
		primaryColor =  singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
	}
	[primaryColor set];

	CGPoint point = CGPointMake(offsetX, 7);
	[movie.title drawAtPoint:point forWidth:forWidth withFont:primaryFont minFontSize:16 actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignCenters];

	point.y = 30;
	[movie.timeString drawAtPoint:point forWidth:forWidth withFont:secondaryFont minFontSize:14 actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignCenters];
}

@end
