//
//  GradientView.m
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "GradientView.h"

@implementation GradientView

@synthesize centerGradient;

- (void)drawRect:(CGRect)rect 
{
	// TODO: need something better than this, this looks terrible when translucent
    CGContextRef currentContext = UIGraphicsGetCurrentContext();

    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t count = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { _startR, _startG, _startB, _startA, _endR, _endG, _endB, _endA};

    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, count);

    CGRect currentBounds = self.bounds;
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMidY(currentBounds));
	CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMaxY(currentBounds));

	if(centerGradient)
	{
		// draw a gradient from top to middle, then reverse the colors and draw from middle to bottom.
		CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, midCenter, 0);
		CGFloat components2[8] = { _endR, _endG, _endB, _endA, _startR, _startG, _startB, _startA };
		CGGradientRelease(glossGradient);
		glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components2, locations, count);
		CGContextDrawLinearGradient(currentContext, glossGradient, midCenter, bottomCenter, 0);
	}
	else
	{
		CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, bottomCenter, 0);
	}

    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace); 
}

- (void)gradientFrom:(UIColor *)from to:(UIColor *)to
{
	CGColorRef ref = [from CGColor];
	const CGFloat *components = CGColorGetComponents(ref);
	_startR = components[0];
	_startG = components[1];
	_startB = components[2];
	_startA = components[3];

	ref = [to CGColor];
	components = CGColorGetComponents(ref);
	_endR = components[0];
	_endG = components[1];
	_endB = components[2];
	_endA = components[3];
}

@end
