//
//  EventTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "EventTableViewCell.h"

#import "NSDateFormatter+FuzzyFormatting.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kEventCell_ID = @"EventCell_ID";

/*!
 @brief Private functions of EventTableViewCell.
 */
@interface EventTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation EventTableViewCell

@synthesize eventNameLabel = _eventNameLabel;
@synthesize eventTimeLabel = _eventTimeLabel;
@synthesize eventServiceLabel = _eventServiceLabel;
@synthesize formatter = _formatter;
@synthesize showService = _showService;


/* deallocate */
- (void)dealloc
{
	[_eventNameLabel release];
	[_eventTimeLabel release];
	[_eventServiceLabel release];
	[_formatter release];
	[_event release];

	[super dealloc];
}

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		const UIView *myContentView = self.contentView;
		_showService = NO;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// A label that displays the Eventname.
		_eventNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: kEventNameTextSize
													bold: YES];
		_eventNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _eventNameLabel];
		
		// A label that displays the Eventtime.
		_eventTimeLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: kEventDetailsTextSize
													bold: NO];
		_eventTimeLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _eventTimeLabel];
		
		// A label that displays the Service name.
		_eventServiceLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
										   selectedColor: [UIColor whiteColor]
												fontSize: kEventDetailsTextSize
													bold: NO];
		_eventServiceLabel.textAlignment = UITextAlignmentRight; // default
		[myContentView addSubview: _eventServiceLabel];
	}

	return self;
}

/* getter for event property */
- (NSObject<EventProtocol> *)event
{
	return _event;
}

/* setter for event property */
- (void)setEvent:(NSObject<EventProtocol> *)newEvent
{
	// Same event, no need to change anything
	if(_event == newEvent) return;

	// Free old event, keep new one
	[_event release];
	_event = [newEvent retain];

	// Check if cache already generated
	if(newEvent.timeString == nil)
	{
		// Not generated, do so...
		[_formatter setDateStyle:NSDateFormatterMediumStyle];
		const NSString *begin = [_formatter fuzzyDate: newEvent.begin];
		[_formatter setDateStyle:NSDateFormatterNoStyle];
		const NSString *end = [_formatter stringFromDate: newEvent.end];
		if(begin && end)
			newEvent.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}

	// Set Labels
	_eventNameLabel.text = newEvent.title;
	_eventTimeLabel.text = newEvent.timeString;
	if(_showService)
	{
		@try{
			_eventServiceLabel.text = newEvent.service.sname;
		}
		@catch(NSException * e){
			_eventServiceLabel.text = @"";
		}
	}
	else
		_eventServiceLabel.text = @"";

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{	
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;

	// NOTE: We actually should never be editing...
	if (!self.editing) {
		CGRect frame;
		const NSInteger serviceOffset = (IS_IPAD()) ? 200 : 90;
		
		// Place the name label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 7, contentRect.size.width - kRightMargin, kEventNameTextSize + 2);
		_eventNameLabel.frame = frame;

		// Place the time label.
		frame.origin.y += frame.size.height + 3;
		frame.size.height = kEventDetailsTextSize + 2;
		_eventTimeLabel.frame = frame;
		
		// Place the service name label.
		frame = CGRectMake(contentRect.size.width - kRightMargin - serviceOffset, frame.origin.y, serviceOffset, kEventDetailsTextSize + 2);
		_eventServiceLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];

	_eventNameLabel.highlighted = selected;
	_eventTimeLabel.highlighted = selected;
	_eventServiceLabel.highlighted = selected;
}

/* Create and configure a label. */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold
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
