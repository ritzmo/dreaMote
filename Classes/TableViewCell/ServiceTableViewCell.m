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

@interface ServiceCellContentView : UIView
@property (nonatomic, strong) CALayer *imageLayer;
@property (nonatomic, unsafe_unretained) UIFont *font;
@property (nonatomic, unsafe_unretained) NSObject<ServiceProtocol> *service;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEditing) BOOL editing;
@end

@implementation ServiceCellContentView

@synthesize editing, font, highlighted, imageLayer, service;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
		imageLayer = [CALayer layer];
		[self.layer addSublayer:imageLayer];
	}
	return self;
}

- (void)setHighlighted:(BOOL)lit
{
	if(highlighted != lit)
	{
		highlighted = lit;
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect
{
	const CGRect contentRect = self.bounds;
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;
	const CGFloat boundsHeight = contentRect.size.height;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *primaryColor = nil;
	if(highlighted)
	{
		primaryColor =  singleton.highlightedTextColor;
	}
	else
	{
		primaryColor =  singleton.textColor;
	}
	[primaryColor set];

	if(self.editing)
		offsetX += kLeftMargin;

	CGPoint point;
	// eventually draw picon
	UIImage *picon = service.picon;
	if(picon)
	{
		CGFloat width = picon.size.width;
		CGFloat height = picon.size.height;
		if(height > boundsHeight)
		{
			width *= boundsHeight/height;
			height = boundsHeight;
		}

		imageLayer.contents = (id)picon.CGImage;
		imageLayer.frame = CGRectMake(offsetX, 0, width, height);
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
	[super drawRect:rect];
}
@end

@interface ServiceTableViewCell()
@property (nonatomic, strong) ServiceCellContentView *cellView;
@end

@implementation ServiceTableViewCell

@synthesize cellView, font, service;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		cellView = [[ServiceCellContentView alloc] initWithFrame:self.contentView.bounds];
		cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:cellView];
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
		cellView.imageLayer.cornerRadius = 10.0;
		cellView.imageLayer.masksToBounds = YES;
	}
	else
	{
		cellView.imageLayer.cornerRadius = 0;
		cellView.imageLayer.masksToBounds = NO;
	}
}

- (void)setFont:(UIFont *)newFont
{
	if(font != newFont)
	{
		font = newFont;
		cellView.font = newFont;
		// NOTE: we don't trigger a redisplay here to optimize things a bit
		//[cellView setNeedsDisplay];
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
	cellView.service = newService;
	[cellView setNeedsDisplay];
}
@end
