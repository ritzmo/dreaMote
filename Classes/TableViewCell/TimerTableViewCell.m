//
//  TimerTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "TimerTableViewCell.h"

#import "Constants.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "Service.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kTimerCell_ID = @"TimerCell_ID";

@implementation TimerTableViewCell

@synthesize timer, formatter;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	return self;
}

/* setter for timer property */
- (void)setTimer:(NSObject<TimerProtocol> *)newTimer
{
	// Abort if same timer assigned
	if(timer == newTimer) return;
	timer = newTimer;

	// Check if time cache is present
	if(!newTimer.timeString)
	{
		// It's not, create it
		[formatter setDateStyle:NSDateFormatterMediumStyle];
		const NSString *begin = [formatter fuzzyDate:newTimer.begin];
		[formatter setDateStyle:NSDateFormatterNoStyle];
		const NSString *end = [formatter stringFromDate:newTimer.end];
		if(begin && end)
			newTimer.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}

	// Redraw
	[self setNeedsDisplay];
}

- (NSString *)accessibilityLabel
{
	return [NSString stringWithFormat:@"%@: %@", timer.service.sname, timer.title];
}

- (NSString *)accessibilityValue
{
	NSString *value = [super accessibilityValue];

	// Generate a new string instead of trying to work with the old one
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	const NSString *begin = [formatter fuzzyDate:timer.begin];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	const NSString *end = [formatter stringFromDate:timer.end];
	NSString *timeString = timer.timeString;
	if(begin && end)
		timeString = [NSString stringWithFormat:NSLocalizedString(@"from %@ to %@", @"Accessibility value for table cells with events (timespan of an event)"), begin, end];

	if(value)
		value = [NSString stringWithFormat:@"%@, %@", timeString, value];
	else
		value = timeString;
	return value;
}

- (void)drawContentRect:(CGRect)contentRect
{
	[super drawContentRect:contentRect];
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIFont *primaryFont = [UIFont boldSystemFontOfSize:singleton.timerServiceTextSize];
	UIFont *secondaryFont = [UIFont boldSystemFontOfSize:singleton.timerNameTextSize];
	UIFont *tertiaryFont = [UIFont systemFontOfSize:singleton.timerTimeTextSize];
	UIColor *primaryColor = nil;
	if(self.highlighted || self.selected)
	{
		primaryColor =  singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
	}
	[primaryColor set];

	CGPoint point = CGPointMake(offsetX + kLeftMargin, 3);
	CGFloat forWidth = boundsWidth - offsetX;
	[timer.service.sname drawAtPoint:point forWidth:forWidth withFont:primaryFont lineBreakMode:UILineBreakModeTailTruncation];
	point.y += primaryFont.lineHeight - 1;

	[timer.title drawAtPoint:point forWidth:forWidth withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];
	point.y += secondaryFont.lineHeight - 2;

	[timer.timeString drawAtPoint:point forWidth:forWidth withFont:tertiaryFont lineBreakMode:UILineBreakModeTailTruncation];
}

@end
