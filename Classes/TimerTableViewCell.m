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

// cell identifier for this custom cell
NSString *kTimerCell_ID = @"TimerCell_ID";

@interface TimerTableViewCell()
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end

@implementation TimerTableViewCell

@synthesize serviceNameLabel = _serviceNameLabel;
@synthesize timerNameLabel = _timerNameLabel;
@synthesize timerTimeLabel = _timerTimeLabel;
@synthesize formatter = _formatter;

- (void)dealloc
{
	[_serviceNameLabel release];
	[_timerNameLabel release];
	[_timerTimeLabel release];
	[_formatter release];
	[_timer release];

	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
		UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Servicename.
		self.serviceNameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES];
		_serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _serviceNameLabel];
		[_serviceNameLabel release];

		// A label that displays the Timername.
		self.timerNameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:12.0 bold:YES];
		_timerNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _timerNameLabel];
		[_timerNameLabel release];

		// A label that displays the Timer time.
		self.timerTimeLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:12.0 bold:NO];
		_timerTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _timerTimeLabel];
		[_timerTimeLabel release];
	}
	
	return self;
}

- (NSObject<TimerProtocol> *)timer
{
	return _timer;
}

- (void)setTimer:(NSObject<TimerProtocol> *)newTimer
{
	if(_timer == newTimer) return;

	[_timer release];
	_timer = [newTimer retain];

	_serviceNameLabel.text = newTimer.service.sname;
	_timerNameLabel.text = newTimer.title;
	if(newTimer.timeString == nil)
	{
		[_formatter setDateStyle:NSDateFormatterMediumStyle];
		NSString *begin = [_formatter stringFromDate: newTimer.begin];
		[_formatter setDateStyle:NSDateFormatterNoStyle];
		NSString *end = [_formatter stringFromDate: newTimer.end];
		if(begin && end)
			newTimer.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}
	_timerTimeLabel.text = newTimer.timeString;

	[self setNeedsDisplay];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	CGRect contentRect = self.contentView.bounds;

	// In this example we will never be editing, but this illustrates the appropriate pattern
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background, so in newLabelForMainText: the labels are made opaque and given a white background.  To show selection properly,   |however, the views need to be transparent (so that the selection color shows through).  
	 */
	[super setSelected:selected animated:animated];

	UIColor *backgroundColor = nil;
	if (selected) {
		backgroundColor = [UIColor clearColor];
	} else {
		backgroundColor = [UIColor whiteColor];
	}

	_serviceNameLabel.backgroundColor = backgroundColor;
	_serviceNameLabel.highlighted = selected;
	_serviceNameLabel.opaque = !selected;

	_timerNameLabel.backgroundColor = backgroundColor;
	_timerNameLabel.highlighted = selected;
	_timerNameLabel.opaque = !selected;

	_timerTimeLabel.backgroundColor = backgroundColor;
	_timerTimeLabel.highlighted = selected;
	_timerTimeLabel.opaque = !selected;
}

- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
	/*
	 Create and configure a label.
	 */
	
	UIFont *font;
	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}

	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background, so set these defaults.  To show selection properly, however, the views need to be transparent (so that the	  |selection color shows through).  This is handled in setSelected:animated:.
	 */
	UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor whiteColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
