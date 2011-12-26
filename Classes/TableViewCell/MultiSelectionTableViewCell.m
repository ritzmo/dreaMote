//
//  MultiSelectionTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 15.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "MultiSelectionTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface MultiSelectionTableViewCell()
- (void)forceMultiSelected:(BOOL)selected;
@property (nonatomic, strong) CALayer *imageLayer;
@end

@implementation MultiSelectionTableViewCell

@synthesize imageLayer;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.backgroundView = [[UIView alloc] init];
		self.shouldIndentWhileEditing = NO;
		imageLayer = [CALayer layer];
		NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										   [NSNull null], @"contents",
										   nil];
		imageLayer.actions = newActions;
		[self addSublayer:imageLayer];
		[self forceMultiSelected:NO];
	}
	return self;
}

- (void)prepareForReuse
{
	[self forceMultiSelected:NO];
	[super prepareForReuse];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	imageLayer.hidden = !editing;

#if IS_DEBUG()
	NSParameterAssert([self.superview isKindOfClass:[UITableView class]]);
#endif

	if([self.superview respondsToSelector:@selector(isEditing)])
	{
		if(_multiSelected && ![(UITableView *)self.superview isEditing])
			[self setMultiSelected:NO animated:YES];
	}
}

- (NSString *)accessibilityValue
{
#if 0
	if(self.editing)
	{
		if(_multiSelected)
			return NSLocalizedString(@"selected", @"Accessibility text for selected cells in multi selection");
		return NSLocalizedString(@"not selected", @"Accessibility text for unselected cells in multi selection");
	}
#endif
	return nil;
}

- (UIAccessibilityTraits)accessibilityTraits
{
	UIAccessibilityTraits traits = UIAccessibilityTraitStaticText;
	if(self.editing && _multiSelected)
		traits |= UIAccessibilityTraitSelected;
	return traits;
}

- (void)forceMultiSelected:(BOOL)selected
{
	_multiSelected = selected;
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
}

- (void)setMultiSelected:(BOOL)selected animated:(BOOL)animated
{
	if(animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2f];
	}

	[self forceMultiSelected:selected];
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
	const CGFloat boundsHeight = contentRect.size.height;
	if(self.editing)
	{
		const NSInteger IMAGE_SIZE = 30;
		CGRect indicatorFrame = CGRectMake(-30,
										   (boundsHeight - IMAGE_SIZE) / 2,
										   IMAGE_SIZE,
										   IMAGE_SIZE);
		imageLayer.frame = indicatorFrame;
	}
}

@end
