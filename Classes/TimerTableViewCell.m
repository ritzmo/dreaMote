//
//  TimerTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerTableViewCell.h"

#import "Constants.h"

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

/* dealloc */
- (void)dealloc
{
	[_serviceNameLabel release];
	[_timerNameLabel release];
	[_timerTimeLabel release];
	[_formatter release];
	[_timer release];

	[super dealloc];
}

/* initialize */
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if(self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier])
	{
		UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Servicename.
		_serviceNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
											 selectedColor: [UIColor whiteColor]
												  fontSize: 14.0
													  bold: YES];
		_serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _serviceNameLabel];

		// A label that displays the Timername.
		_timerNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: 12.0
													bold: YES];
		_timerNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _timerNameLabel];

		// A label that displays the Timer time.
		_timerTimeLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: 12.0
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

	// Free old timer, assign new one
	[_timer release];
	_timer = [newTimer retain];

	// Check if time cache is present
	if(newTimer.timeString == nil)
	{
		// It's not, create it
		[_formatter setDateStyle:NSDateFormatterMediumStyle];
		NSString *begin = [_formatter stringFromDate: newTimer.begin];
		[_formatter setDateStyle:NSDateFormatterNoStyle];
		NSString *end = [_formatter stringFromDate: newTimer.end];
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
	CGRect contentRect;

	[super layoutSubviews];
	contentRect = self.contentView.bounds;

	if (!self.editing) {
		CGRect frame;

		// Place the name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 7, contentRect.size.width - kRightMargin, 14);
		_serviceNameLabel.frame = frame;

		// Place the other name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 25, contentRect.size.width - kRightMargin, 14);
		_timerNameLabel.frame = frame;

		// Place the time label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 41, contentRect.size.width - kRightMargin, 10);
		_timerTimeLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	UIColor *backgroundColor = nil;

	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background,
	 so in newLabelForMainText: the labels are made opaque and given a white background.
	 
	 To show selection properly, however, the views need to be transparent (so that the selection
	 color shows through).
	 */
	[super setSelected:selected animated:animated];

	if (selected) {
		backgroundColor = [UIColor clearColor];
	} else {
		backgroundColor = [UIColor whiteColor];
	}

	// Service
	_serviceNameLabel.backgroundColor = backgroundColor;
	_serviceNameLabel.highlighted = selected;
	_serviceNameLabel.opaque = !selected;

	// Name
	_timerNameLabel.backgroundColor = backgroundColor;
	_timerNameLabel.highlighted = selected;
	_timerNameLabel.opaque = !selected;

	// Time
	_timerTimeLabel.backgroundColor = backgroundColor;
	_timerTimeLabel.highlighted = selected;
	_timerTimeLabel.opaque = !selected;
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

	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background,
	 so in newLabelForMainText: the labels are made opaque and given a white background.
	 
	 To show selection properly, however, the views need to be transparent (so that the selection
	 color shows through).
	 This is handled in setSelected:animated:
	 */
	newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor whiteColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
