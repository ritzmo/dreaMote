//
//  EventTableViewCell.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventTableViewCell.h"

#import "AppDelegateMethods.h"

@implementation EventTableViewCell

@synthesize event = _event;

+ (void)initialize
{
	// TODO: anything to be done here?
}	

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(CGRect)clip
{
	#define COLUMN_X 5.0
	#define MAX_WIDTH 305.0

	// Render Event name
	[[UIColor blackColor] set];
    NSString *eventname = [_event title];
	CGRect contentRect = [self contentRectForBounds:self.bounds];
	CGFloat x = contentRect.origin.x + COLUMN_X;
	[eventname drawAtPoint:CGPointMake(x, 7.0) forWidth:MAX_WIDTH withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeTailTruncation];

	// Render <begin date> <begin time> - <end time>
	//NSDate *begin = [NSDate dateWithTimeIntervalSince1970: [[_event begin] doubleValue]];
	//NSDate *end = [NSDate dateWithTimeIntervalSince1970: [[_event begin] doubleValue]+[[_event duration] doubleValue]];
	NSString *time = [NSString stringWithFormat: @"%@ - %@", [[_event begin] descriptionWithCalendarFormat:@"%d.%m. %H:%M" timeZone:nil locale:nil], [[_event end] descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil]];
	[time drawAtPoint:CGPointMake(x, 28) forWidth:MAX_WIDTH withFont:[UIFont italicSystemFontOfSize:10] lineBreakMode:UILineBreakModeTailTruncation];

    [super drawRect:clip];
}

@end