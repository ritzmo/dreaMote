//
//  PackageCell.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "PackageCell.h"

#import <QuartzCore/QuartzCore.h>

#import "Constants.h"

// cell identifier for this custom cell
NSString *kPackageCell_ID = @"PlayListCell_ID";

@interface PackageCell()
@property (nonatomic, strong) CALayer *imageLayer;
@end

@implementation PackageCell

@synthesize imageLayer, package;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		self.backgroundView = [[UIView alloc] init];
		self.shouldIndentWhileEditing = NO;
		imageLayer = [CALayer layer];
		[self addSublayer:imageLayer];
	}
	return self;
}

- (void)prepareForReuse
{
	[self setMultiSelected:NO animated:NO];
	// NOTE: don't unset package to avoid a redraw...
}

- (Package *)package
{
	return package;
}

- (void)setPackage:(Package *)newPackage
{
	if(package == newPackage) return;
	package = newPackage;

	[self setNeedsDisplay];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];

#if IS_DEBUG()
	NSParameterAssert([self.superview isKindOfClass:[UITableView class]]);
#endif

	if([self.superview respondsToSelector:@selector(isEditing)])
	{
		if(_multiSelected && ![(UITableView *)self.superview isEditing])
			[self setMultiSelected:NO animated:YES];
	}
}

- (void)setMultiSelected:(BOOL)selected animated:(BOOL)animated
{
	_multiSelected = selected;
	if(animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2f];
	}

	if(selected)
	{
		indicatorImage = [UIImage imageNamed:@"IsSelected.png"];
		imageLayer.contents = (id)indicatorImage.CGImage;
		self.backgroundView.backgroundColor = [UIColor colorWithRed:223.0f/255.0f green:230.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
	}
	else
	{
		indicatorImage = [UIImage imageNamed:@"NotSelected.png"];
		imageLayer.contents = (id)indicatorImage.CGImage;
		self.backgroundView.backgroundColor = [UIColor clearColor];
	}
	[self setNeedsDisplay];
	if(animated)
	{
		[UIView commitAnimations];
	}
}

- (BOOL)toggleMultiSelected
{
	[self setMultiSelected:!_multiSelected animated:YES];
	return _multiSelected;
}

- (void)drawContentRect:(CGRect)contentRect
{
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;
	const CGFloat boundsHeight = contentRect.size.height;

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

	if(indicatorImage && self.editing)
	{
		const NSInteger IMAGE_SIZE = 30;
		CGRect indicatorFrame = CGRectMake(-30,
										   (boundsHeight - IMAGE_SIZE) / 2,
										   IMAGE_SIZE,
										   IMAGE_SIZE);
		imageLayer.frame = indicatorFrame;
		imageLayer.hidden = NO;
	}
	else
		imageLayer.hidden = YES;
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
