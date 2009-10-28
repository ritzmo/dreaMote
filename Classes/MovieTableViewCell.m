//
//  MovieTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"
#import "MovieTableViewCell.h"

#import "FuzzyDateFormatter.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMovieCell_ID = @"MovieCell_ID";

/*!
 @brief Private functions of MovieTableViewCell.
 */
@interface MovieTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation MovieTableViewCell

@synthesize eventNameLabel = _eventNameLabel;
@synthesize eventTimeLabel = _eventTimeLabel;
@synthesize formatter = _formatter;

/* dealloc */
- (void)dealloc
{
	[_eventNameLabel release];
	[_eventTimeLabel release];
	[_movie release];
	[_formatter release];

	[super dealloc];
}

/* initialize */
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
#ifdef __IPHONE_3_0
	if(self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier])
#else
	if(self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier])
#endif
	{
		const UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Eventname.
		_eventNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: 14.0
													bold: YES];
		_eventNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _eventNameLabel];
		
		// A label that displays the Eventtime.
		_eventTimeLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: 10.0
													bold: NO];
		_eventTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _eventTimeLabel];
	}
	
	return self;
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

	// Free old movie, assign new one
	[_movie release];
	_movie = [newMovie retain];

	// Set new label contents
	_eventNameLabel.text = newMovie.title;
	_eventTimeLabel.text = [_formatter stringFromDate: newMovie.time];

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;

	// XXX: we should never be editing.
	if (!self.editing) {
		CGRect frame;
		
		// Place the name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 7, contentRect.size.width - kRightMargin, 16);
		_eventNameLabel.frame = frame;

		// Place the time label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 30, contentRect.size.width - kRightMargin, 14);
		_eventTimeLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL) selected animated:(BOOL) animated
{
	[super setSelected:selected animated:animated];

	_eventNameLabel.highlighted = selected;
	_eventTimeLabel.highlighted = selected;
}

/* Create and configure a label. */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold
{
	UIFont *font;
	UILabel *newLabel;

	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}

	newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor clearColor];
	newLabel.opaque = NO;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
