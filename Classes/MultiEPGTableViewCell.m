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

#define kServiceWidth ((IS_IPAD()) ? 150 : 75)

/*!
 @brief Private functions of ServiceTableViewCell.
 */
@interface MultiEPGTableViewCell()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation MultiEPGTableViewCell

@synthesize serviceNameLabel = _serviceNameLabel;
@synthesize begin = _begin;

/* dealloc */
- (void)dealloc
{
	[_serviceNameLabel release];
	[_service release];
	[_events release];
	[_begin release];
	[_lines release];

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
												  fontSize: kMultiEPGFontSize
													  bold: YES];
		_serviceNameLabel.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview: _serviceNameLabel];

		// no accessory
		self.accessoryType = UITableViewCellAccessoryNone;
		
		_lines = [[NSMutableArray alloc] init];
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

/* getter of events property */
- (NSArray *)events
{
	return _events;
}

/* setter of events property */
- (void)setEvents:(NSArray *)new
{
	if(_events == new) return;

	[_events release];
	_events = [new retain];

	[_lines removeAllObjects];
	for(NSObject<EventProtocol> *event in _events)
	{
		CGFloat left = (CGFloat)[event.begin timeIntervalSinceDate:_begin];
		if(left < 0)
			left = 0;
		[_lines addObject:[NSNumber numberWithFloat:left]];
	}

	// Redraw
	[self setNeedsDisplay];
}

- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point
{
	const CGFloat widthPerSecond = (self.bounds.size.width - kServiceWidth) / 7200.0f;
	const NSInteger count = [_lines count] - 1;
	NSInteger idx = 0;
	for(NSObject<EventProtocol> *event in _events)
	{
		const CGFloat leftLine = kServiceWidth + [[_lines objectAtIndex:idx] floatValue] * widthPerSecond;
		const CGFloat rightLine = (idx < count) ? kServiceWidth + [[_lines objectAtIndex:idx+1] floatValue] * widthPerSecond: self.bounds.size.width;

		// if x withing bounds of event, return it… ignore y for now, should not matter anyway.
		if(point.x >= leftLine && point.x < rightLine)
		{
			return [[event retain] autorelease];
		}
		idx += 1;
	}
	return nil;
}

/* draw cell */
- (void)drawRect:(CGRect)rect
{
	const CGRect contentRect = self.contentView.bounds;
	const CGFloat widthPerSecond = (contentRect.size.width - kServiceWidth) / 7200.0f;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0.5f, 0.5f, 0.5f, 1.0f);
	CGContextSetLineWidth(ctx, 0.25f);

	for(NSNumber *number in _lines)
	{
		const CGFloat xPos = kServiceWidth + [number floatValue] * widthPerSecond;
		CGContextMoveToPoint(ctx, xPos, 0);
		CGContextAddLineToPoint(ctx, xPos, contentRect.size.height);
	}
	CGContextStrokePath(ctx);

	[super drawRect:rect];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;
	const CGFloat widthPerSecond = (contentRect.size.width - kServiceWidth) / 7200.0f;

	// Place the location label.
	if(_service.valid)
	{
		const CGRect frame = CGRectMake(contentRect.origin.x, 0, kServiceWidth, contentRect.size.height);
		_serviceNameLabel.frame = frame;
	}
	else
	{
		const CGRect frame = CGRectMake(contentRect.origin.x + kLeftMargin, 0, contentRect.size.width - kLeftMargin - kRightMargin, contentRect.size.height);
		_serviceNameLabel.numberOfLines = 1;
		_serviceNameLabel.adjustsFontSizeToFitWidth = NO;
		_serviceNameLabel.frame = frame;
	}
	[self.contentView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	[self.contentView addSubview:_serviceNameLabel];

	NSInteger idx = 0;
	const NSInteger count = [_lines count] - 1;
	for(NSObject<EventProtocol> *event in _events)
	{
		const CGFloat leftLine = [[_lines objectAtIndex:idx] floatValue] * widthPerSecond;
		CGFloat rightLine = (idx < count) ? [[_lines objectAtIndex:idx+1] floatValue] * widthPerSecond: contentRect.size.width - kServiceWidth;
		rightLine -= leftLine;
		const CGRect frame = CGRectMake(kServiceWidth + leftLine, 0, rightLine, contentRect.size.height);
		idx += 1;

		UILabel *label = [self newLabelWithPrimaryColor: [UIColor blackColor]
										  selectedColor: [UIColor whiteColor]
											   fontSize: kMultiEPGFontSize
												   bold: NO];
		label.text = event.title;
		label.frame = frame;
		label.adjustsFontSizeToFitWidth = YES;
		label.textAlignment = UITextAlignmentCenter;
		[self.contentView addSubview:label];
		[label release];
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
	newLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	newLabel.numberOfLines = 0;
	newLabel.adjustsFontSizeToFitWidth = YES;
	
	return newLabel;
}

@end