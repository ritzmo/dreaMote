//
//  EventTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventTableViewCell.h"

#import "Constants.h"

#import "NSDateFormatter+FuzzyFormatting.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kEventCell_ID = @"EventCell_ID";

@implementation EventTableViewCell

@synthesize event, formatter, showService;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return self;
}

/* setter for event property */
- (void)setEvent:(NSObject<EventProtocol> *)newEvent
{
	// Same event, no need to change anything
	if(event == newEvent) return;
	event = newEvent;

	// Check if cache already generated
	if(newEvent.timeString == nil)
	{
		// Not generated, do so...
		[formatter setDateStyle:NSDateFormatterMediumStyle];
		const NSString *begin = [formatter fuzzyDate:newEvent.begin];
		[formatter setDateStyle:NSDateFormatterNoStyle];
		const NSString *end = [formatter stringFromDate:newEvent.end];
		if(begin && end)
			newEvent.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
	}

	// Redraw
	[self setNeedsDisplay];
}

- (void)drawContentRect:(CGRect)contentRect
{
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *primaryColor = nil, *secondaryColor = nil;
	UIFont *primaryFont = [UIFont boldSystemFontOfSize:singleton.eventNameTextSize];
	UIFont *secondaryFont = [UIFont systemFontOfSize:singleton.eventDetailsTextSize];
	if(self.highlighted)
	{
		primaryColor =  secondaryColor = singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  secondaryColor = singleton.textColor;
	}
	[primaryColor set];

	CGPoint point;
	const NSInteger serviceOffset = (IS_IPAD()) ? 200 : 90;

	point = CGPointMake(offsetX + kLeftMargin, 7);
	[event.title drawAtPoint:point forWidth:boundsWidth-point.x withFont:primaryFont lineBreakMode:UILineBreakModeTailTruncation];

	point.y += primaryFont.lineHeight;
	[event.timeString drawAtPoint:point forWidth:boundsWidth-point.x withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];

	if(showService)
	{
		@try
		{
			NSString *text = event.service.sname;
			CGSize size = [text sizeWithFont:secondaryFont forWidth:serviceOffset lineBreakMode:UILineBreakModeTailTruncation];

			point = CGPointMake(boundsWidth - size.width, point.y);
			[text drawAtPoint:point forWidth:size.width withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];
		}
		@catch(NSException *e)
		{
			// ignore
		}
	}
}

@end
