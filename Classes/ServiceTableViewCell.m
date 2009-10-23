//
//  ServiceTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
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
	if(self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier])
#else
	if(self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier])
#endif
	{
		UIView *myContentView = self.contentView;

		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryNone;

		// A label that displays the Servicename.
		_serviceNameLabel = [self newLabelWithPrimaryColor: [UIColor blackColor]
											 selectedColor: [UIColor whiteColor]
												  fontSize: 14.0
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

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	CGRect contentRect;

	[super layoutSubviews];
	contentRect = self.contentView.bounds;
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
	if (!self.editing) {
		CGRect frame;
		
		// Place the location label.
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 1, contentRect.size.width - kRightMargin, 20);
		_serviceNameLabel.frame = frame;
	}
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	UIColor *backgroundColor = nil;

	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background,
	 so in newLabelForMainText: the labels are made opaque and given a white background.
	 
	 To show selection properly, however, the views need to be transparent (so that the selection
	 color shows through).
	 */
	[super setSelected:selected animated:animated];

	if (selected) {
		backgroundColor = [UIColor clearColor];
	} else {
		backgroundColor = [UIColor whiteColor];
	}

	_serviceNameLabel.backgroundColor = backgroundColor;
	_serviceNameLabel.highlighted = selected;
	_serviceNameLabel.opaque = !selected;
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
	
	/*
	 Views are drawn most efficiently when they are opaque and do not have a clear background,
	 so in newLabelForMainText: the labels are made opaque and given a white background.
	 
	 To show selection properly, however, the views need to be transparent (so that the selection
	 color shows through).
	 This is handled in setSelected:animated:
	 */
	newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor whiteColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
