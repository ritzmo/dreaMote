//
//  ServiceTableViewCell.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceTableViewCell.h"
#import "AppDelegateMethods.h"

@implementation ServiceTableViewCell

@synthesize service = _service;

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

	// Just a plain black service name
	[[UIColor blackColor] set];
    NSString *servicename = [_service getServiceName];
	CGRect contentRect = [self contentRectForBounds: self.bounds];
	CGFloat x = contentRect.origin.x + COLUMN_X;
	[servicename drawAtPoint: CGPointMake(x, 7.0) forWidth: MAX_WIDTH withFont: [UIFont boldSystemFontOfSize: 14] lineBreakMode: UILineBreakModeTailTruncation];
	
    [super drawRect:clip];
}

@end