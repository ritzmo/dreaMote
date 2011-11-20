//
//  GradientView.m
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "GradientView.h"

#import <Categories/UIDevice+SystemVersion.h>

#import <QuartzCore/QuartzCore.h>

@implementation GradientView

+ (Class)layerClass
{
	return [CAGradientLayer class];
}

- (void)gradientFrom:(UIColor *)from to:(UIColor *)to center:(BOOL)center
{
	NSArray *colors = nil, *locations = nil;
	if(center)
	{
		CGFloat val1, val2, val3, alpha;
		UIColor *intermediateColor = nil;
		if([UIDevice newerThanIos:5.0f])
		{
			if([from getHue:&val1 saturation:&val2 brightness:&val3 alpha:&alpha])
			{
				intermediateColor = [UIColor colorWithHue:val1 saturation:val2 brightness:val3-.1 alpha:alpha];
			}
			else if([from getRed:&val1 green:&val2 blue:&val3 alpha:&alpha])
			{
				intermediateColor = [UIColor colorWithRed:val1-5 green:val2-5 blue:val3-5 alpha:alpha];
			}
		}
		else
		{
			size_t numComponents = CGColorGetNumberOfComponents(from.CGColor);
			if(numComponents == 4)
			{
				const CGFloat *components = CGColorGetComponents(from.CGColor);
				val1 = components[0];
				val2 = components[1];
				val3 = components[2];
				alpha = components[3];
				intermediateColor = [UIColor colorWithRed:val1-5 green:val2-5 blue:val3-5 alpha:alpha];
			}
		}
		colors = [NSArray arrayWithObjects:(id)from.CGColor, intermediateColor.CGColor, to.CGColor, intermediateColor.CGColor, from.CGColor, nil];
		locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0.1], [NSNumber numberWithFloat:.5], [NSNumber numberWithFloat:.9], [NSNumber numberWithFloat:1], nil];
	}
	else
	{
		CGFloat val1, val2, val3, alpha;
		UIColor *color1 = nil, *color2 = nil;
		if([UIDevice newerThanIos:5.0f])
		{
			if([from getHue:&val1 saturation:&val2 brightness:&val3 alpha:&alpha])
			{
				color1 = [UIColor colorWithHue:val1 saturation:val2 brightness:val3-.1 alpha:alpha];
			}
			else if([from getRed:&val1 green:&val2 blue:&val3 alpha:&alpha])
			{
				color1 = [UIColor colorWithRed:val1-5 green:val2-5 blue:val3-5 alpha:alpha];
			}
			if([to getHue:&val1 saturation:&val2 brightness:&val3 alpha:&alpha])
			{
				color2 = [UIColor colorWithHue:val1 saturation:val2 brightness:val3-.1 alpha:alpha];
			}
			else if([to getRed:&val1 green:&val2 blue:&val3 alpha:&alpha])
			{
				color2 = [UIColor colorWithRed:val1-5 green:val2-5 blue:val3-5 alpha:alpha];
			}
		}
		else
		{
			size_t numComponents = CGColorGetNumberOfComponents(from.CGColor);
			if(numComponents == 4)
			{
				const CGFloat *components = CGColorGetComponents(from.CGColor);
				val1 = components[0];
				val2 = components[1];
				val3 = components[2];
				alpha = components[3];
				color1 = [UIColor colorWithRed:val1-5 green:val2-5 blue:val3-5 alpha:alpha];
			}
			numComponents = CGColorGetNumberOfComponents(to.CGColor);
			if(numComponents == 4)
			{
				const CGFloat *components = CGColorGetComponents(to.CGColor);
				val1 = components[0];
				val2 = components[1];
				val3 = components[2];
				alpha = components[3];
				color2 = [UIColor colorWithRed:val1-5 green:val2-5 blue:val3-5 alpha:alpha];
			}
		}
		colors = [NSArray arrayWithObjects:(id)from.CGColor, color1.CGColor, color2.CGColor, to.CGColor, nil];
		locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:.02], [NSNumber numberWithFloat:.98], [NSNumber numberWithFloat:1], nil];
	}

	((CAGradientLayer *)self.layer).colors = colors;
	((CAGradientLayer *)self.layer).locations = locations;
}

@end
