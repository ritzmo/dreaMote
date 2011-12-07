//
//  ServiceEventTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "ServiceEventTableViewCell.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kServiceEventCell_ID = @"ServiceEventCell_ID";

@implementation ServiceEventTableViewCell

@synthesize formatter, now, next;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryType = UITableViewCellAccessoryNone;
		self.backgroundColor = [UIColor clearColor];

		NSString *localeIdentifier = [[NSLocale componentsFromLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]] objectForKey:NSLocaleLanguageCode];
		if([localeIdentifier isEqualToString:@"de"])
			timeWidth = (IS_IPAD()) ? 100 : 80;
		else // tested for en_US
			timeWidth = (IS_IPAD()) ? 150 : 110;
	}

	return self;
}

/* setter for now property */
- (void)setNow:(NSObject<EventProtocol> *)new
{
	// Abort if same event assigned
	if([now isEqual:new]) return;
	now = new;

	NSDate *beginDate = new.begin;

	// Check if valid event data
	if(beginDate)
	{
		// Check if cache already generated
		if(new.timeString == nil)
		{
			// Not generated, do so...
			const NSString *begin = [formatter stringFromDate:beginDate];
			const NSString *end = [formatter stringFromDate:new.end];
			if(begin && end)
				new.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
		}
	}
	if(new.service.valid)
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else
		self.accessoryType = UITableViewCellAccessoryNone;

	// don't redraw until next is set
}

/* setter of next property */
- (void)setNext:(NSObject<EventProtocol> *)new
{
	// Abort if same event assigned and not nil
	if([new isEqual:next]) return;
	next = new;

	NSDate *beginDate = new.begin;

	// Check if valid event data
	if(beginDate)
	{
		// Check if cache already generated
		if(new.timeString == nil)
		{
			// Not generated, do so...
			const NSString *begin = [formatter stringFromDate:beginDate];
			const NSString *end = [formatter stringFromDate:new.end];
			if(begin && end)
				new.timeString = [NSString stringWithFormat: @"%@ - %@", begin, end];
		}
	}

	[self setNeedsDisplay];
}

- (void)drawContentRect:(CGRect)contentRect
{
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;
	const CGFloat boundsHeight = contentRect.size.height;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *primaryColor = nil;
	UIFont *primaryFont = [UIFont boldSystemFontOfSize:singleton.serviceEventServiceSize];
	UIFont *secondaryFont = [UIFont systemFontOfSize:singleton.serviceEventEventSize];
	if(self.highlighted)
	{
		primaryColor =  singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
	}
	[primaryColor set];

	if(self.editing)
		offsetX += kLeftMargin;

	CGPoint point;
	// invalid data or marker - center and left align title
	if(!now.valid || !now.service.valid)
	{
		NSString *text = now.valid ? now.service.sname : now.title;
		point = CGPointMake(offsetX, (boundsHeight - primaryFont.lineHeight) / 2);
		[text drawAtPoint:point forWidth:boundsWidth-offsetX withFont:primaryFont lineBreakMode:UILineBreakModeTailTruncation];
		return;
	}
	// eventually draw picon
	UIImage *picon = now.service.piconLoaded ? now.service.picon : nil;
	if(picon)
	{
		if(picon.size.height > boundsHeight)
		{
			CGSize size = CGSizeMake(picon.size.width*(boundsHeight/picon.size.height), boundsHeight);
			UIGraphicsBeginImageContextWithOptions(size, NO, 0);
			CGContextRef context = UIGraphicsGetCurrentContext();

			// Flip the context because UIKit coordinate system is upside down to Quartz coordinate system
			CGContextTranslateCTM(context, 0.0, boundsHeight);
			CGContextScaleCTM(context, 1.0, -1.0);

			// Draw the original image to the context
			CGContextSetBlendMode(context, kCGBlendModeCopy);
			CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, boundsHeight), picon.CGImage);

			// Retrieve the UIImage from the current context
			picon = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
		}

		point = CGPointMake(offsetX, (boundsHeight - picon.size.height) / 2);
		[picon drawAtPoint:point];
		offsetX += picon.size.width;
	}
	else
		offsetX += kLeftMargin;

	CGFloat forWidth = boundsWidth-offsetX;
	// draw service name
	point = CGPointMake(offsetX, 0);
	[now.service.sname drawAtPoint:point forWidth:forWidth withFont:primaryFont lineBreakMode:UILineBreakModeTailTruncation];

	// draw 'now time' if present
	point.y += primaryFont.lineHeight - 2; // XXX: wtf?
	[now.timeString drawAtPoint:point forWidth:timeWidth withFont:secondaryFont minFontSize:8 actualFontSize:NULL lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

	point.x += 5 + timeWidth;
	forWidth = boundsWidth - point.x;
	if(!now.begin)
	{
		[NSLocalizedString(@"No EPG", @"Placeholder text in Now/Next-ServiceList if no EPG data present") drawAtPoint:point forWidth:forWidth withFont:secondaryFont lineBreakMode:UILineBreakModeClip];
		return;
	}
	[now.title drawAtPoint:point forWidth:forWidth withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];

	if(next.begin)
	{
		point.x = offsetX;
		point.y += secondaryFont.lineHeight;
		[next.timeString drawAtPoint:point forWidth:timeWidth withFont:secondaryFont minFontSize:8 actualFontSize:NULL lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
		point.x += 5 + timeWidth;
		[next.title drawAtPoint:point forWidth:forWidth withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];
	}
}

@end
