//
//  PackageCell.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "PackageCell.h"

#import "Constants.h"

// cell identifier for this custom cell
NSString *kPackageCell_ID = @"PlayListCell_ID";

@implementation PackageCell

@synthesize package;

- (void)setPackage:(Package *)newPackage
{
	if(package == newPackage) return;
	package = newPackage;

	[self setNeedsDisplay];
}

- (void)drawContentRect:(CGRect)contentRect
{
	[super drawContentRect:contentRect]; // set frame for multi selection pixmap

	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *primaryColor = nil, *secondaryColor = nil;
	UIFont *primaryFont = [UIFont boldSystemFontOfSize:singleton.packageNameTextSize];
	UIFont *secondaryFont = [UIFont boldSystemFontOfSize:singleton.packageVersionTextSize];
	if(self.highlighted)
	{
		primaryColor =  singleton.highlightedTextColor;
		secondaryColor = singleton.highlightedDetailsTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
		secondaryColor = singleton.detailsTextColor;
	}
	[primaryColor set];

	offsetX += kRightMargin;

	// package name
	CGFloat forWidth = boundsWidth-offsetX;
	CGPoint point = CGPointMake(offsetX, kTopMargin);
	[package.name drawAtPoint:point forWidth:forWidth withFont:primaryFont minFontSize:14 actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignCenters];

	// version information
	point.y += primaryFont.lineHeight - 3;
	[secondaryColor set];
	if(package.upgradeVersion)
	{
		forWidth /= 2;
		CGSize size = [package.upgradeVersion sizeWithFont:secondaryFont forWidth:forWidth lineBreakMode:UILineBreakModeTailTruncation];

		point = CGPointMake(boundsWidth - size.width, point.y);
		[package.upgradeVersion drawAtPoint:point forWidth:size.width withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];

		point.x = offsetX;
	}
	[package.version drawAtPoint:point forWidth:forWidth withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];
}

@end
