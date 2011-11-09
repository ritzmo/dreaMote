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

/*!
 @brief Private functions of TimerTableViewCell.
 */
@interface AutoTimerTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation AutoTimerTableViewCell

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		const UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		_timerNameLabel = [self newLabelWithPrimaryColor:nil
										   selectedColor:[DreamoteConfiguration singleton].highlightedTextColor
												fontSize:kAutoTimerNameTextSize
													bold:YES];
		[myContentView addSubview:_timerNameLabel];
	}
	
	return self;
}

- (void)theme
{
	_timerNameLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	[super theme];
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
	if(_timer == newTimer) return;
	_timer = newTimer;

	_timerNameLabel.text = newTimer.name;
	if(newTimer.enabled)
		_timerNameLabel.textColor = [DreamoteConfiguration singleton].textColor;
	else
		_timerNameLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;

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
		_timerNameLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	_timerNameLabel.highlighted = selected;
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
