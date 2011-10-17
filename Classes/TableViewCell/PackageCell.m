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

		versionLabel = [self newLabelWithPrimaryColor:[UIColor blackColor]
										selectedColor:[UIColor whiteColor]
											 fontSize:kPackageVersionTextSize
												 bold:YES];

		availableLabel = [self newLabelWithPrimaryColor:[UIColor blackColor]
										  selectedColor:[UIColor whiteColor]
											   fontSize:kPackageVersionTextSize
												   bold:YES];

		indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotSelected.png"]];
		indicator.frame = CGRectZero;
		[self.contentView addSubview:indicator];

		self.backgroundView = [[[UIView alloc] init] autorelease];
	}
	return self;
}

- (void)prepareForReuse
{
	[self setMultiSelected:NO animated:NO];
	self.textLabel.text = nil;
	versionLabel.text = nil;
	availableLabel.text = nil;
	self.package = nil;
}

- (Package *)package
{
	return package;
}

- (void)setPackage:(Package *)newPackage
{
	if(package == newPackage) return;
	SafeRetainAssign(package, newPackage);

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
}

- (void)dealloc
{
	[availableLabel release];
	[indicator release];
	[versionLabel release];

    [super dealloc];
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
