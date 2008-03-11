//
//  TimerTableViewCell.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerTableViewCell.h"

#import "AppDelegateMethods.h"

@implementation TimerTableViewCell

@synthesize timer = _timer;

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
	NSString *servicename = [[_timer service] sname];
	CGRect contentRect = [self contentRectForBounds:self.bounds];
	CGFloat x = contentRect.origin.x + COLUMN_X;
	[servicename drawAtPoint:CGPointMake(x, 7.0) forWidth:MAX_WIDTH withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeTailTruncation];

	// Render Timer name
	[[UIColor blackColor] set];
	NSString *timername = [_timer title];
	contentRect = [self contentRectForBounds:self.bounds];
	[timername drawAtPoint:CGPointMake(x, 26.0) forWidth:MAX_WIDTH withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeTailTruncation];

	// Render <begin date> <begin time> - <end time>
	NSString *time = [NSString stringWithFormat: @"%@ - %@", [[_timer begin] descriptionWithCalendarFormat:@"%d.%m. %H:%M" timeZone:nil locale:nil], [[_timer end] descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil]];
	[time drawAtPoint:CGPointMake(x, 41.0) forWidth:MAX_WIDTH withFont:[UIFont italicSystemFontOfSize:12] lineBreakMode:UILineBreakModeTailTruncation];
	
    [super drawRect:clip];
}

@end
