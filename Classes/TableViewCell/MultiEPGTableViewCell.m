//
//  MultiEPGTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "MultiEPGTableViewCell.h"

#if IS_DEBUG()
#import "NSDateFormatter+FuzzyFormatting.h"
#endif

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMultiEPGCell_ID = @"MultiEPGCell_ID";

#define kServiceWidth ((IS_IPAD()) ? 100 : 70)

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

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
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
		_secondsSinceBegin = -1;
	}

	return self;
}

- (void)prepareForReuse
{
	self.events = nil;
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
	SafeRetainAssign(_service, newService);

	// Change name
	_serviceNameLabel.text = newService.sname;
	self.imageView.image = newService.picon;

	// Redraw
	[self setNeedsDisplay];
}

/* getter of events property */
- (NSArray *)events
{
	@synchronized(self)
	{
		return _events;
	}
}

/* setter of events property */
- (void)setEvents:(NSArray *)new
{
	@synchronized(self)
	{
		if(_events == new) return;
		SafeRetainAssign(_events, new);

		[_lines removeAllObjects];
		for(NSObject<EventProtocol> *event in _events)
		{
			CGFloat left = (CGFloat)[event.begin timeIntervalSinceDate:_begin];
			[_lines addObject:[NSNumber numberWithFloat:left]];
		}

		// Redraw
		[self setNeedsDisplay];
	}
}


/* getter of secondsSinceBegin property */
- (NSTimeInterval)secondsSinceBegin
{
	return _secondsSinceBegin;
}

/* setter of now property */
- (void)setSecondsSinceBegin:(NSTimeInterval)secondsSinceBegin
{
	if(_secondsSinceBegin == secondsSinceBegin) return;
	_secondsSinceBegin = secondsSinceBegin;

	// Redraw
	[self setNeedsDisplay];
}

- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point
{
	const NSInteger count = [_lines count] - 1;
	if(count == -1)
	{
		NSLog(@"invalid number of lines (0) in multi epg cell, returning first event if possible or nil");
		if([_events count])
			[_events objectAtIndex:0];
		return nil;
	}

	const CGFloat widthPerSecond = (self.bounds.size.width - kServiceWidth) / [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	NSInteger idx = 0;
	for(NSObject<EventProtocol> *event in _events)
	{
		const CGFloat eventBegin = [[_lines objectAtIndex:idx] floatValue];
		const CGFloat leftLine = (eventBegin < 0) ? kServiceWidth : kServiceWidth + eventBegin * widthPerSecond;
		const CGFloat rightLine = (idx < count) ? kServiceWidth + [[_lines objectAtIndex:idx+1] floatValue] * widthPerSecond: self.bounds.size.width;

		// if x withing bounds of event, return it… ignore y for now, should not matter anyway.
		if(point.x >= leftLine && point.x < rightLine)
		{
			return event;
		}
		idx += 1;
	}
	return nil;
}

/* draw cell */
- (void)drawRect:(CGRect)rect
{
	const CGRect contentRect = self.contentView.bounds;
	const CGFloat multiEpgInterval = [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	const CGFloat widthPerSecond = (contentRect.size.width - kServiceWidth) / multiEpgInterval;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0.5f, 0.5f, 0.5f, 1.0f);
	CGContextSetRGBFillColor(ctx, 0.0f, 1.0f, 0.0f, 0.5f);
	CGContextSetLineWidth(ctx, 0.25f);
	const CGFloat xPosNow = kServiceWidth + (CGFloat)_secondsSinceBegin * widthPerSecond;
	CGFloat rectX = NSNotFound, rectW = NSNotFound;

	CGFloat lastBegin = NSNotFound;
	for(NSNumber *number in _lines)
	{
		const CGFloat eventBegin = [number floatValue];
		const CGFloat xPos = (eventBegin < 0) ? kServiceWidth : kServiceWidth + eventBegin * widthPerSecond;
		if(eventBegin <= _secondsSinceBegin)
		{
			rectX = xPos;
			lastBegin = eventBegin;
		}
		else if(rectX != NSNotFound && lastBegin != NSNotFound && lastBegin <= _secondsSinceBegin)
		{
			rectW = xPos - rectX;
			lastBegin = NSNotFound;
		}
		CGContextMoveToPoint(ctx, xPos, 0);
		CGContextAddLineToPoint(ctx, xPos, contentRect.size.height);
	}
	CGContextStrokePath(ctx);
	if(lastBegin != NSNotFound) // we found a potential match
	{
		// check if this is just the last event so we had nothing to compare it to
		NSObject<EventProtocol> *lastEvent = ((NSObject<EventProtocol> *)[_events lastObject]);
		if([lastEvent.begin timeIntervalSinceDate:_begin] == lastBegin)
		{
			const NSTimeInterval lastEnd = [lastEvent.end timeIntervalSinceDate:_begin];
			if(lastEnd < _secondsSinceBegin)
				rectX = NSNotFound;
			else
				rectW = contentRect.size.width - rectX;
		}
	}
	if(rectX != NSNotFound && rectW != NSNotFound)
		CGContextFillRect(ctx, CGRectMake(rectX, 0, rectW, contentRect.size.height));

	// now
	if(_secondsSinceBegin > -1 && _secondsSinceBegin <= multiEpgInterval)
	{
		CGContextSetRGBStrokeColor(ctx, 1.0f, 0.0f, 0.0f, 0.8f);
		CGContextSetLineWidth(ctx, 0.4f);
		CGContextMoveToPoint(ctx, xPosNow, 0);
		CGContextAddLineToPoint(ctx, xPosNow, contentRect.size.height);
		CGContextStrokePath(ctx);
	}

	[super drawRect:rect];
}

/* layout */
- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = self.contentView.bounds;
	const CGFloat widthPerSecond = (contentRect.size.width - kServiceWidth) / [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];

	// Place the location label.
	if(_service.valid)
	{
		const CGRect frame = CGRectMake(contentRect.origin.x, 0, kServiceWidth, contentRect.size.height);
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
			_serviceNameLabel.frame = CGRectZero;
		}
		else
		{
			_serviceNameLabel.numberOfLines = 0;
			_serviceNameLabel.adjustsFontSizeToFitWidth = YES;
			_serviceNameLabel.frame = frame;
		}
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
	[self.contentView addSubview:self.imageView];

	NSInteger idx = 0;
	const NSInteger count = [_lines count] - 1;
	for(NSObject<EventProtocol> *event in self.events)
	{
		CGFloat leftLine;
		CGFloat rightLine;
		@try
		{
			const CGFloat eventBegin = [[_lines objectAtIndex:idx] floatValue];
			leftLine = (eventBegin < 0) ? 0 : eventBegin * widthPerSecond;
			rightLine = (idx < count) ? [[_lines objectAtIndex:idx+1] floatValue] * widthPerSecond: contentRect.size.width - kServiceWidth;
		}
		@catch(NSException *exception)
		{
#if IS_DEBUG()
			NSLog(@"Exception in [MultiEPGTableViewCell layoutSubviews]: idx %d, count %d, count events %d", idx, count, self.events.count);
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateStyle:NSDateFormatterNoStyle];
			[formatter setTimeStyle:NSDateFormatterShortStyle];
			NSLog(@"Service: %@", _service.sname);
			for(NSObject<EventProtocol> *event in _events)
			{
				NSLog(@"Event: %@, %@ - %@", event.title, [formatter fuzzyDate:event.begin], [formatter fuzzyDate:event.end]);
			}
			for(NSNumber *number in _lines)
			{
				NSLog(@"Line: %.2f", kServiceWidth + [number floatValue] * widthPerSecond);
			}
			[exception raise];
#endif
			break;
		}

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
