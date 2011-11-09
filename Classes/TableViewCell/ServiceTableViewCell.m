//
//  ServiceTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "ServiceTableViewCell.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kServiceCell_ID = @"ServiceCell_ID";

/*!
 @brief Private functions of ServiceTableViewCell.
 */
@interface ServiceTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation ServiceTableViewCell

@synthesize loadPicon;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.textLabel.font = [UIFont boldSystemFontOfSize:kServiceTextSize];
		self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;

		loadPicon = YES;
	}

	return self;
}

- (void)theme
{
	self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
	self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	[super theme];
}

- (void)prepareForReuse
{
	self.accessoryType = UITableViewCellAccessoryNone;
	self.imageView.image = nil;
	self.service = nil;

	[super prepareForReuse];
}

- (UILabel *)serviceNameLabel
{
	return self.textLabel;
}

/* getter for service property */
- (NSObject<ServiceProtocol> *)service
{
	return _service;
}

/* setter for service property */
- (void)setService:(NSObject<ServiceProtocol> *)newService
{
	// Abort if same service assigned
	if(_service == newService) return;
	_service = newService;

	// Change name
	self.textLabel.text = newService.sname;

	if(newService.valid)
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if(newService.piconLoaded || loadPicon)
			self.imageView.image = newService.picon;
	}

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;

	CGRect imageRect = self.imageView.frame;
	if(self.editing)
		imageRect.origin.x += kLeftMargin;
	self.imageView.frame = imageRect;
	const NSInteger leftMargin = contentRect.origin.x + ((self.imageView.image) ? (imageRect.size.width + imageRect.origin.x + kTweenMargin) : kLeftMargin);
	const CGRect frame = CGRectMake(leftMargin, 1, contentRect.size.width - leftMargin - kRightMargin, contentRect.size.height - 2);
	self.textLabel.frame = frame;
}

/* Create and configure a label. */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold
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
