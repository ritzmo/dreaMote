//
//  MultiEPGTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "MultiEPGTableViewCell.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMultiEPGCell_ID = @"MultiEPGCell_ID";

@implementation MultiEPGTableViewCell

@synthesize epgView;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.textLabel.font = [UIFont boldSystemFontOfSize:kMultiEPGFontSize];
		self.accessoryType = UITableViewCellAccessoryNone;
		self.backgroundColor = [UIColor clearColor];

		epgView = [[MultiEPGCellContentView alloc] initWithFrame:CGRectZero];
		epgView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self.contentView addSubview:epgView];
	}

	return self;
}

- (void)prepareForReuse
{
	self.service = nil;
	epgView.events = nil;
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
	self.imageView.image = newService.picon;

	// Redraw
	[self setNeedsDisplay];
}

- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point
{
	const NSInteger serviceWidth = kMultiEPGServiceWidth;
	if(point.x < serviceWidth)
		return nil;

	CGPoint newPoint = point;
	newPoint.x -= serviceWidth;
	return [epgView eventAtPoint:newPoint];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;
	const NSInteger serviceWidth = kMultiEPGServiceWidth;

	// Place the location label.
	if(_service.valid)
	{
		const CGRect frame = CGRectMake(contentRect.origin.x, 0, serviceWidth, contentRect.size.height);
		if(self.imageView.image)
		{
			CGRect realFrame = frame;
			CGSize imageSize = self.imageView.image.size;
			realFrame.size.width = frame.size.height * (imageSize.width / imageSize.height);
			if(realFrame.size.width > frame.size.width)
				realFrame.size.width = frame.size.width;
			else if(realFrame.size.width != frame.size.width)
			{
				// center picon
				realFrame.origin.x = realFrame.origin.x + (frame.size.width - realFrame.size.width) / 2.0f;
			}
			self.imageView.frame = realFrame;
			self.textLabel.frame = CGRectZero;
		}
		else
		{
			self.textLabel.numberOfLines = 0;
			self.textLabel.adjustsFontSizeToFitWidth = YES;
			self.textLabel.frame = frame;
		}
		epgView.frame = CGRectMake(contentRect.origin.x + serviceWidth, 0, contentRect.size.width - serviceWidth, contentRect.size.height);
	}
	else
	{
		const CGRect frame = CGRectMake(contentRect.origin.x + kLeftMargin, 0, contentRect.size.width - kLeftMargin - kRightMargin, contentRect.size.height);
		self.textLabel.numberOfLines = 1;
		self.textLabel.adjustsFontSizeToFitWidth = NO;
		self.textLabel.frame = frame;
	}
}

@end
