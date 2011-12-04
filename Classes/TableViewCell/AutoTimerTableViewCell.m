//
//  AutoTimerTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 10.04.10.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerTableViewCell.h"

#import "Constants.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "Service.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kAutoTimerCell_ID = @"AutoTimerCell_ID";

@implementation AutoTimerTableViewCell

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.textLabel.font = [UIFont boldSystemFontOfSize:kAutoTimerNameTextSize];
		self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	}
	
	return self;
}

/* getter for timer property */
- (AutoTimer *)timer
{
	return _timer;
}

/* setter for timer property */
- (void)setTimer:(AutoTimer *)newTimer
{
	// Abort if same timer assigned
	if(newTimer.enabled)
		self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
	else
		self.textLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;

	if(_timer == newTimer) return;
	_timer = newTimer;

	self.textLabel.text = newTimer.name;

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;

	if(!self.editing)
	{
		CGRect frame;

		frame = CGRectMake(contentRect.origin.x + kLeftMargin, contentRect.origin.y, contentRect.size.width - (kLeftMargin + kRightMargin), contentRect.size.height);
		self.textLabel.frame = frame;
	}
}

@end
