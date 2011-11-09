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

/*!
 @brief Private functions of PackageCell.
 */
@interface PackageCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation PackageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		self.textLabel.font = [UIFont boldSystemFontOfSize:kPackageNameTextSize];
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.adjustsFontSizeToFitWidth = YES;

		versionLabel = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].detailsTextColor
										selectedColor:[DreamoteConfiguration singleton].highlightedDetailsTextColor
											 fontSize:kPackageVersionTextSize
												 bold:YES];
		versionLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:versionLabel];

		availableLabel = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].detailsTextColor
										  selectedColor:[DreamoteConfiguration singleton].highlightedDetailsTextColor
											   fontSize:kPackageVersionTextSize
												   bold:YES];
		availableLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:availableLabel];

		indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotSelected.png"]];
		indicator.frame = CGRectZero;
		[self.contentView addSubview:indicator];

		self.backgroundView = [[UIView alloc] init];
	}
	return self;
}

- (void)theme
{
	versionLabel.textColor = [DreamoteConfiguration singleton].textColor;
	versionLabel.textColor = [DreamoteConfiguration singleton].highlightedTextColor;
	availableLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;
	availableLabel.textColor = [DreamoteConfiguration singleton].highlightedDetailsTextColor;
	[super theme];
}

- (void)prepareForReuse
{
	[self setMultiSelected:NO animated:NO];
	self.package = nil;
}

- (Package *)package
{
	return package;
}

- (void)setPackage:(Package *)newPackage
{
	if(package == newPackage) return;
	package = newPackage;

	self.textLabel.text = package.name;
	versionLabel.text = package.version;
	availableLabel.text = package.upgradeVersion;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	// prevent some gui glitches
	if(editing != self.editing)
	{
		[super setEditing:editing animated:animated];
		// WTF?!
		self.textLabel.backgroundColor = [UIColor clearColor];
		versionLabel.backgroundColor = [UIColor clearColor];
		availableLabel.backgroundColor = [UIColor clearColor];
	}

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
		indicator.image = [UIImage imageNamed:@"IsSelected.png"];
		self.backgroundView.backgroundColor = [UIColor colorWithRed:223.0f/255.0f green:230.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
	}
	else
	{
		indicator.image = [UIImage imageNamed:@"NotSelected.png"];
		self.backgroundView.backgroundColor = [UIColor whiteColor];
	}

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

- (void)layoutSubviews
{
	[super layoutSubviews];
	CGRect contentRect = [self.contentView bounds];

	if(self.editing)
	{
		const NSInteger IMAGE_SIZE = 30;
		CGRect indicatorFrame = CGRectMake(-30,
										   (0.5f * contentRect.size.height) - (0.5f * IMAGE_SIZE),
										   IMAGE_SIZE,
										   IMAGE_SIZE);
		indicator.frame = indicatorFrame;
	}

#if 0
	if(package.upgradeVersion && IS_IPAD())
	{
		CGRect frame = CGRectMake(
								  contentRect.origin.x + kLeftMargin,
								  (contentRect.size.height - kPackageNameTextSize) / 2.0f,
								  [self.textLabel sizeThatFits:self.textLabel.bounds.size].width,
								  kPackageNameTextSize
		);
		self.textLabel.frame = frame;

		const CGFloat availableWidth = [availableLabel sizeThatFits:availableLabel.bounds.size].width;
		const CGFloat versionWidth = [versionLabel sizeThatFits:versionLabel.bounds.size].width;
		const CGFloat xOffset = fminf(fminf(availableWidth, versionWidth), contentRect.size.width - frame.size.width);
		frame = CGRectMake(
						   contentRect.size.width - xOffset - kRightMargin,
						   kTopMargin,
						   xOffset,
						   kPackageVersionTextSize
						   );
		versionLabel.frame = frame;

		frame.origin.y = contentRect.size.height - kPackageVersionTextSize - kBottomMargin;
		availableLabel.frame = frame;
	}
	else
#endif
	{
		CGRect frame = CGRectMake(
								  contentRect.origin.x + kRightMargin,
								  kTopMargin,
								  contentRect.size.width,
								  kPackageNameTextSize
		);
		self.textLabel.frame = frame;

		frame.origin.y = contentRect.size.height - kPackageNameTextSize - kBottomMargin;
		if(package.upgradeVersion)
		{
			frame.size.width = contentRect.size.width / 2.0f - kRightMargin - kLeftMargin - kTweenMargin;
			frame.origin.x = contentRect.size.width - frame.size.width;
			availableLabel.frame = frame;

			frame.origin.x = contentRect.origin.x + kRightMargin;
		}
		versionLabel.frame = frame;
	}
}

						  
/* Create and configure a label. */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
	UIFont *font;
	UILabel *newLabel;
	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}
	
	newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor clearColor];
	newLabel.opaque = NO;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
