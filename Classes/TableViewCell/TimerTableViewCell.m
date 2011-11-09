//
//  TimerTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "TimerTableViewCell.h"

#import "Constants.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "Service.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kTimerCell_ID = @"TimerCell_ID";

/*!
 @brief Private functions of TimerTableViewCell.
 */
@interface TimerTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation TimerTableViewCell

@synthesize formatter;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]))
	{
		const UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		self.textLabel.font = [UIFont boldSystemFontOfSize:kTimerServiceTextSize];
		self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;

		self.detailTextLabel.font = [UIFont boldSystemFontOfSize:kTimerNameTextSize];
		self.detailTextLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.detailTextLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;

		// A label that displays the Timer time.
		_timerTimeLabel = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].textColor
										   selectedColor:[DreamoteConfiguration singleton].highlightedTextColor
												fontSize:kTimerTimeTextSize
													bold:NO];
		[myContentView addSubview: _timerTimeLabel];
	}
	
	return self;
}

- (void)theme
{
	self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
	self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	self.detailTextLabel.textColor = [DreamoteConfiguration singleton].textColor;
	self.detailTextLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	_timerTimeLabel.textColor = [DreamoteConfiguration singleton].textColor;
	_timerTimeLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	[super theme];
}

/* getter for timer property */
- (NSObject<TimerProtocol> *)timer
{
	return _timer;
}

/* setter for timer property */
- (void)setTimer:(NSObject<TimerProtocol> *)newTimer
{
	// Abort if same timer assigned
	if(_timer == newTimer) return;
	_timer = newTimer;

	// Check if time cache is present
	if(newTimer.timeString == nil)
	{
		// It's not, create it
		[formatter setDateStyle:NSDateFormatterMediumStyle];
		const NSString *begin = [formatter fuzzyDate:newTimer.begin];
		[formatter setDateStyle:NSDateFormatterNoStyle];
		const NSString *end = [formatter stringFromDate:newTimer.end];
		if(begin && end)
			newTimer.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}

	// Change label texts
	self.textLabel.text = newTimer.service.sname;
	self.detailTextLabel.text = newTimer.title;
	_timerTimeLabel.text = newTimer.timeString;

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;

	if (!self.editing) {
		CGRect frame;
		CGFloat offset = 7;

		// Place the name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, offset, contentRect.size.width - kRightMargin, kTimerNameTextSize + 2);
		self.textLabel.frame = frame;
		if(IS_IPAD())
			offset += kTimerServiceTextSize;
		else
			offset = 25;

		// Place the other name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, offset - 1, contentRect.size.width - kRightMargin, kTimerNameTextSize + 2);
		self.detailTextLabel.frame = frame;
		if(IS_IPAD())
			offset += kTimerNameTextSize;
		else
			offset = 40;

		// Place the time label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, offset, contentRect.size.width - kRightMargin, kTimerTimeTextSize + 2);
		_timerTimeLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	_timerTimeLabel.highlighted = selected;
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
