//
//  EventTableViewCell.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"
#import "EventTableViewCell.h"

// cell identifier for this custom cell
NSString *kEventCell_ID = @"EventCell_ID";

@interface EventTableViewCell()
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end

@implementation EventTableViewCell

@synthesize eventNameLabel = _eventNameLabel;
@synthesize eventTimeLabel = _eventTimeLabel;
@synthesize formatter = _formatter;

- (void)dealloc
{
	[_eventNameLabel release];
	[_eventTimeLabel release];
	[_formatter release];
	[_event release];

	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
		UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Eventname.
		self.eventNameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES];
		_eventNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _eventNameLabel];
		[_eventNameLabel release];
		
		// A label that displays the Eventtime.
		self.eventTimeLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:10.0 bold:NO];
		_eventTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _eventTimeLabel];
		[_eventTimeLabel release];
	}
	
	return self;
}

- (Event *)event
{
	return _event;
}

- (void)setEvent:(Event *)newEvent
{
	if(_event == newEvent) return;

	[_event release];
	_event = [newEvent retain];

	_eventNameLabel.text = newEvent.title;
	if(newEvent.timeString == nil)
	{
		[_formatter setDateStyle:NSDateFormatterMediumStyle];
		NSString *begin = [_formatter stringFromDate: newEvent.begin];
		[_formatter setDateStyle:NSDateFormatterNoStyle];
		NSString *end = [_formatter stringFromDate: newEvent.end];
		newEvent.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}
	_eventTimeLabel.text = newEvent.timeString;

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
		_eventNameLabel.frame = frame;

		// Place the time label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 30, contentRect.size.width - kRightMargin, 10);
		_eventTimeLabel.frame = frame;
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
	
	_eventNameLabel.backgroundColor = backgroundColor;
	_eventNameLabel.highlighted = selected;
	_eventNameLabel.opaque = !selected;
	
	_eventTimeLabel.backgroundColor = backgroundColor;
	_eventTimeLabel.highlighted = selected;
	_eventTimeLabel.opaque = !selected;
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
