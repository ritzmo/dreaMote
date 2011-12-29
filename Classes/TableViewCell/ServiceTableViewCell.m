//
//  ServiceTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "ServiceTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

/*!
 @brief Cell identifier for this cell.
 */
NSString *kServiceCell_ID = @"ServiceCell_ID";

@interface ServiceTableViewCell()
@property (nonatomic, strong) CALayer *imageLayer;
@end

@implementation ServiceTableViewCell

@synthesize font, imageLayer, loadPicon, service;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		loadPicon = YES;
		imageLayer = [CALayer layer];
		NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										   [NSNull null], @"contents",
										   nil];
		imageLayer.actions = newActions;
		[self addSublayer:imageLayer];
		self.font = [UIFont boldSystemFontOfSize:[DreamoteConfiguration singleton].serviceTextSize];
	}
	return self;
}

- (void)prepareForReuse
{
	self.accessoryType = UITableViewCellAccessoryNone;
	// NOTE: we don't release our strong or the cellView's borrowed references here to avoid a draw operation

	[super prepareForReuse];
}

- (void)setRoundedPicons:(BOOL)roundedPicons
{
	if(roundedPicons)
	{
		imageLayer.cornerRadius = 10.0;
		imageLayer.masksToBounds = YES;
	}
	else
	{
		imageLayer.cornerRadius = 0;
		imageLayer.masksToBounds = NO;
	}
}

/* setter for service property */
- (void)setService:(NSObject<ServiceProtocol> *)newService
{
	// Abort if same service assigned
	if(service == newService) return;
	service = newService;

	if(newService.valid)
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	[self setNeedsDisplay];
}

- (NSString *)accessibilityLabel
{
	return service.sname;
}

- (void)drawContentRect:(CGRect)contentRect
{
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;
	const CGFloat boundsHeight = contentRect.size.height;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *primaryColor = nil;
	if(self.highlighted || self.selected)
	{
		primaryColor =  singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
	}
	[primaryColor set];

	CGPoint point;
	// eventually draw picon
	UIImage *picon = (loadPicon || service.piconLoaded) ? service.picon : nil;
	if(picon)
	{
		CGFloat width = picon.size.width;
		CGFloat height = picon.size.height;
		if(height > boundsHeight)
		{
			width *= boundsHeight/height;
			height = boundsHeight;
		}

		CGRect frame = CGRectMake(offsetX, 0, width, height);
		if(self.editing)
			frame.origin.x = kLeftMargin;
		imageLayer.contents = (id)picon.CGImage;
		imageLayer.frame = frame;
		offsetX += width + kTweenMargin;
	}
	else
	{
		imageLayer.contents = nil;
		offsetX += kLeftMargin;
	}

	CGFloat forWidth = boundsWidth-offsetX;
	point = CGPointMake(offsetX, (boundsHeight - font.lineHeight) / 2);
	[service.sname drawAtPoint:point forWidth:forWidth withFont:font lineBreakMode:UILineBreakModeTailTruncation];
	//[super drawRect:rect];
}

@end
