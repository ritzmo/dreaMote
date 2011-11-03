//
//  PlayListCell.m
//  dreaMote
//
//  Created by Moritz Venn on 29.05.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "PlayListCell.h"

#import "Constants.h"

// cell identifier for this custom cell
NSString *kPlayListCell_ID = @"PlayListCell_ID";

@implementation PlayListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		self.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
		self.textLabel.backgroundColor = [UIColor clearColor];

		indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotSelected.png"]];
		indicator.frame = CGRectZero;
		[self.contentView addSubview:indicator];

		self.backgroundView = [[UIView alloc] init];
	}
	return self;
}

- (void)prepareForReuse
{
	[self setMultiSelected:NO animated:NO];
	self.textLabel.text = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	// prevent some gui glitches
	if(editing != self.editing)
	{
		[super setEditing:editing animated:animated];
		self.textLabel.backgroundColor = [UIColor clearColor]; // WTF?!
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


@end
