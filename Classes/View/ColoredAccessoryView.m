//
//  ColoredAccessoryView.m
//  dreaMote
//
//  Based on DTCustomColoredAccessory from http://www.cocoanetics.com/2010/10/custom-colored-disclosure-indicators/
//
//  Created by Moritz Venn on 09.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "ColoredAccessoryView.h"

@implementation ColoredAccessoryView

@synthesize accessoryColor, highlightedColor;

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

+ (ColoredAccessoryView *)accessoryViewWithColor:(UIColor *)color andHighlightedColor:(UIColor *)highlightedColor
{
	ColoredAccessoryView *av = [[ColoredAccessoryView alloc] initWithFrame:CGRectMake(0, 0, 11.0, 15.0)];
	av.accessoryColor = color;
	av.highlightedColor = highlightedColor;
	return av;
}

- (void)drawRect:(CGRect)rect
{
	// (x,y) is the tip of the arrow
	const CGFloat x = CGRectGetMaxX(self.bounds)-3.0;;
	const CGFloat y = CGRectGetMidY(self.bounds);
	const CGFloat R = 4.5;
	CGContextRef ctxt = UIGraphicsGetCurrentContext();
	CGContextMoveToPoint(ctxt, x-R, y-R);
	CGContextAddLineToPoint(ctxt, x, y);
	CGContextAddLineToPoint(ctxt, x-R, y+R);
	CGContextSetLineCap(ctxt, kCGLineCapSquare);
	CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
	CGContextSetLineWidth(ctxt, 3);
	
	if(self.highlighted)
		[self.highlightedColor setStroke];
	else
		[self.accessoryColor setStroke];

	CGContextStrokePath(ctxt);
}

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

- (UIColor *)accessoryColor
{
	if (!accessoryColor)
		return [UIColor blackColor];
	return accessoryColor;
}

- (UIColor *)highlightedColor
{
	if (!highlightedColor)
		return [UIColor whiteColor];
	return highlightedColor;
}

@end