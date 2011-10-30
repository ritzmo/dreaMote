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

@synthesize serviceNameLabel = _serviceNameLabel;
@synthesize timerNameLabel = _timerNameLabel;
@synthesize timerTimeLabel = _timerTimeLabel;
@synthesize formatter = _formatter;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		const UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Servicename.
		_serviceNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
											 selectedColor: [UIColor whiteColor]
												  fontSize: kTimerServiceTextSize
													  bold: YES];
		_serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _serviceNameLabel];

		// A label that displays the Timername.
		_timerNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: kTimerNameTextSize
													bold: YES];
		_timerNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _timerNameLabel];

		// A label that displays the Timer time.
		_timerTimeLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: kTimerTimeTextSize
													bold: NO];
		_timerTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _timerTimeLabel];
	}
	
	return self;
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
	SafeRetainAssign(_timer, newTimer);

	// Check if time cache is present
	if(newTimer.timeString == nil)
	{
		// It's not, create it
		[_formatter setDateStyle:NSDateFormatterMediumStyle];
		const NSString *begin = [_formatter fuzzyDate: newTimer.begin];
		[_formatter setDateStyle:NSDateFormatterNoStyle];
		const NSString *end = [_formatter stringFromDate: newTimer.end];
		if(begin && end)
			newTimer.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}

	// Change label texts
	_serviceNameLabel.text = newTimer.service.sname;
	_timerNameLabel.text = newTimer.title;
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
		_serviceNameLabel.frame = frame;
		if(IS_IPAD())
			offset += kTimerServiceTextSize;
		else
			offset = 25;

		// Place the other name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, offset - 1, contentRect.size.width - kRightMargin, kTimerNameTextSize + 2);
		_timerNameLabel.frame = frame;
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
	_serviceNameLabel.highlighted = selected;
	_timerNameLabel.highlighted = selected;
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
