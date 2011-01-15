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

@synthesize serviceNameLabel = _serviceNameLabel;

/* dealloc */
- (void)dealloc
{
	[_serviceNameLabel release];
	[_service release];

	[super dealloc];
}

/* initialize */
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
#ifdef __IPHONE_3_0
	if((self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier]))
#else
	if((self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier]))
#endif
	{
		const UIView *myContentView = self.contentView;

		// A label that displays the Servicename.
		_serviceNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
											 selectedColor: [UIColor whiteColor]
												  fontSize: kServiceTextSize
													  bold: YES];
		_serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _serviceNameLabel];
	}

	return self;
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

	// Free old service, assign new one
	[_service release];
	_service = [newService retain];

	// Change name
	_serviceNameLabel.text = newService.sname;

	if(newService.valid)
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else
		self.accessoryType = UITableViewCellAccessoryNone;

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
	if (!self.editing)
	{
		// Place the location label.
		const CGRect frame = CGRectMake(contentRect.origin.x + kLeftMargin, 1, contentRect.size.width - kRightMargin, contentRect.size.height - 2);
		_serviceNameLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];

	_serviceNameLabel.highlighted = selected;
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
