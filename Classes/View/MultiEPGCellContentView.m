//
//  MultiEPGCellContentView.m
//  dreaMote
//
//  Created by Moritz Venn on 11.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGCellContentView.h"

#import <Constants.h>

#if IS_DEBUG()
	#import "NSDateFormatter+FuzzyFormatting.h"
#endif

/*!
 @brief Private functions of ServiceTableViewCell.
 */
@interface MultiEPGCellContentView()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation MultiEPGCellContentView

@synthesize begin;

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = [UIColor clearColor];
        _lines = [[NSMutableArray alloc] init];
		_secondsSinceBegin = -1;
    }
    return self;
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
		_events = new;

		[_lines removeAllObjects];
		for(NSObject<EventProtocol> *event in _events)
		{
			CGFloat left = (CGFloat)[event.begin timeIntervalSinceDate:begin];
			[_lines addObject:[NSNumber numberWithFloat:left]];
		}

		// Redraw
		[self setNeedsDisplay];
		[self setNeedsLayout];
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

	const CGFloat widthPerSecond = self.bounds.size.width / [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	NSInteger idx = 0;
	for(NSObject<EventProtocol> *event in _events)
	{
		const CGFloat eventBegin = [[_lines objectAtIndex:idx] floatValue];
		const CGFloat leftLine = (eventBegin < 0) ? 0 : eventBegin * widthPerSecond;
		const CGFloat rightLine = (idx < count) ? [[_lines objectAtIndex:idx+1] floatValue] * widthPerSecond: self.bounds.size.width;

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
	const CGRect contentRect = self.bounds;
	const CGFloat multiEpgInterval = [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	const CGFloat widthPerSecond = contentRect.size.width / multiEpgInterval;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0.5f, 0.5f, 0.5f, 1.0f);
	[[DreamoteConfiguration singleton].multiEpgFillColor setFill];
	CGContextSetLineWidth(ctx, 0.25f);
	const CGFloat xPosNow = (CGFloat)_secondsSinceBegin * widthPerSecond;
	CGFloat rectX = NSNotFound, rectW = NSNotFound;

	CGFloat lastBegin = NSNotFound;
	for(NSNumber *number in _lines)
	{
		const CGFloat eventBegin = [number floatValue];
		const CGFloat xPos = (eventBegin < 0) ? 0 : eventBegin * widthPerSecond;
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
		if([lastEvent.begin timeIntervalSinceDate:begin] == lastBegin)
		{
			const NSTimeInterval lastEnd = [lastEvent.end timeIntervalSinceDate:begin];
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

/* layout subviews */
// TODO: stuff in here is fairly static, why do we do this as often?
- (void)layoutSubviews
{
	const CGRect contentRect = self.bounds;
	const CGFloat widthPerSecond = contentRect.size.width / [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	const DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];

	[self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	NSInteger idx = 0;
	const NSInteger count = [_lines count] - 1;
	UIColor *primaryColor = singleton.textColor;
	UIColor *selectedColor = singleton.highlightedTextColor;
	CGFloat fontSize = singleton.multiEpgFontSize;
	for(NSObject<EventProtocol> *event in self.events)
	{
		CGFloat leftLine;
		CGFloat rightLine;
		@try
		{
			const CGFloat eventBegin = [[_lines objectAtIndex:idx] floatValue];
			leftLine = (eventBegin < 0) ? 0 : eventBegin * widthPerSecond;
			rightLine = (idx < count) ? [[_lines objectAtIndex:idx+1] floatValue] * widthPerSecond: contentRect.size.width;
		}
		@catch(NSException *exception)
		{
#if IS_DEBUG()
			NSLog(@"Exception in [MultiEPGTableViewCell layoutSubviews]: idx %d, count %d, count events %d", idx, count, self.events.count);
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateStyle:NSDateFormatterNoStyle];
			[formatter setTimeStyle:NSDateFormatterShortStyle];
			for(NSObject<EventProtocol> *event in _events)
			{
				NSLog(@"Event: %@, %@ - %@", event.title, [formatter fuzzyDate:event.begin], [formatter fuzzyDate:event.end]);
			}
			for(NSNumber *number in _lines)
			{
				NSLog(@"Line: %.2f", [number floatValue] * widthPerSecond);
			}
			[exception raise];
#endif
			break;
		}

		rightLine -= leftLine;
		const CGRect frame = CGRectMake(leftLine, 0, rightLine, contentRect.size.height);
		idx += 1;

		UILabel *label = [self newLabelWithPrimaryColor:primaryColor
										  selectedColor:selectedColor
											   fontSize:fontSize
												   bold:NO];
		label.text = event.title;
		label.frame = frame;
		label.adjustsFontSizeToFitWidth = YES;
		label.textAlignment = UITextAlignmentCenter;
		[self addSubview:label];
	}
	[super layoutSubviews];
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
