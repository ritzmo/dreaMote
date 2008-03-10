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
	#define LOCATION_COLUMN_X 5.0
	#define LOCATION_WIDTH 200.0
	
	#define MAGNITUDE_WIDTH 100.0

	// Just a plain black timer name
	// TODO: add begin/end, maybe service - see e2 timer overview for reference
	[[UIColor blackColor] set];
    NSString *timername = [_timer title];
	CGRect contentRect = [self contentRectForBounds:self.bounds];
	CGFloat x = contentRect.origin.x + LOCATION_COLUMN_X;
	[timername drawAtPoint:CGPointMake(x, 7.0) forWidth:LOCATION_WIDTH withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeTailTruncation];
	
    [super drawRect:clip];
}

@end
