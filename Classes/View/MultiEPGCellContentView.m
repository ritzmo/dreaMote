//
//  MultiEPGCellContentView.m
//  dreaMote
//
//  Created by Moritz Venn on 11.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGCellContentView.h"

#import <Constants.h>
#import <Objects/Generic/Event.h>

#import <Categories/NSDateFormatter+FuzzyFormatting.h>

#pragma mark - Accessibility Helper classes

@interface MutliEPGAccessibilityElement : UIAccessibilityElement
@property (nonatomic, strong) NSObject<EventProtocol> *event;
@end

@implementation MutliEPGAccessibilityElement
@synthesize event;
- (NSString *)accessibilityLabel
{
	return event.title;
}
- (NSString *)accessibilityValue
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	const NSString *begin = [formatter fuzzyDate:event.begin];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	const NSString *end = [formatter stringFromDate:event.end];
	if(begin && end)
		return [NSString stringWithFormat:NSLocalizedString(@"from %@ to %@", @"Accessibility value for table cells with events (timespan of an event)"), begin, end];
	return event.timeString;
}
@end

#pragma mark - Cell

/*!
 @brief Private functions of ServiceTableViewCell.
 */
@interface MultiEPGCellContentView()
/*!
 @brief Currently playing event or nil if not in range.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *currentEvent;
@property (nonatomic, strong) NSArray *accessibilityElements;
@end

@implementation MultiEPGCellContentView

@synthesize accessibilityElements, begin, currentEvent, highlighted;

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = [UIColor clearColor];
		self.contentMode = UIViewContentModeRedraw;
		_secondsSinceBegin = NSNotFound;
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
	if(!CGRectEqualToRect(frame, self.frame))
	{
		[super setFrame:frame];
		self.accessibilityElements = nil;
	}
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
	self.accessibilityElements = nil; // always reset these in case of orientation change
	@synchronized(self)
	{
		if(_events == new) return;
		_events = new;

		self.currentEvent = nil;

		// wait a few moments with the redraw until we know when 'now' is
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
	_secondsSinceBegin = secondsSinceBegin;

	const float interval = [[NSUserDefaults standardUserDefaults] floatForKey:kMultiEPGInterval];
	if(currentEvent && [currentEvent.begin timeIntervalSinceDate:begin] <= secondsSinceBegin && [currentEvent.end timeIntervalSinceDate:begin] > secondsSinceBegin)
	{
		// nothing (current event still active)
	}
	// no current event or not in timespan any longer
	else
	{
		if(secondsSinceBegin < 0)
		{
			NSObject<EventProtocol> *firstObject = [_events count] ? [_events objectAtIndex:0] : nil;
			if(firstObject && [firstObject.begin timeIntervalSinceDate:begin] < secondsSinceBegin)
			{
				self.currentEvent = firstObject;
			}
		}
		else if(_secondsSinceBegin > interval)
		{
			NSObject<EventProtocol> *lastObject = [_events lastObject];
			if(lastObject && [lastObject.end timeIntervalSinceDate:begin] > secondsSinceBegin)
			{
				self.currentEvent = lastObject;
			}
		}
		else
		{
			for(NSObject<EventProtocol> *event in _events)
			{
				if([event.begin timeIntervalSinceDate:begin] <= secondsSinceBegin && [event.end timeIntervalSinceDate:begin] > secondsSinceBegin)
				{
					self.currentEvent = event;
					break;
				}
			}
		}
	}

	// Redraw
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)lit
{
	if(highlighted != lit)
	{
		highlighted = lit;
		[self setNeedsDisplay];
	}
}

- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point
{
	const CGFloat widthPerSecond = self.bounds.size.width / [[NSUserDefaults standardUserDefaults] floatForKey:kMultiEPGInterval];

	// NOTE: we iterate through the array and check the previous events begin against our begin
	// this should fix possible problems with overlapping events
	NSObject<EventProtocol> *prevEvent = nil;
	CGFloat prevLine = 0;
	for(NSObject<EventProtocol> *event in _events)
	{
		if(prevEvent == nil)
		{
			const CGFloat eventBegin = [event.begin timeIntervalSinceDate:begin];
			prevLine = (eventBegin < 0) ? 0 : eventBegin * widthPerSecond;
			if(point.x < prevLine)
				break;
			prevEvent = event;
			continue;
		}
		const CGFloat leftLine = prevLine;
		prevLine = [event.begin timeIntervalSinceDate:begin] * widthPerSecond;

		// if x within bounds of previous event, return it…
		if(point.x >= leftLine && point.x < prevLine)
		{
			return prevEvent;
		}
		prevEvent = event;
	}
	return prevEvent; // last event or nil if there are none
}

/* draw cell */
- (void)drawRect:(CGRect)rect
{
	const CGRect contentRect = self.bounds;
	const CGFloat multiEpgInterval = [[NSUserDefaults standardUserDefaults] floatForKey:kMultiEPGInterval];
	const CGFloat widthPerSecond = contentRect.size.width / multiEpgInterval;
	const CGFloat boundsX = contentRect.origin.x;
	const CGFloat boundsHeight = contentRect.size.height;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(ctx, 0.25f);

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIColor *color = nil;
	if(highlighted)
	{
		color = singleton.highlightedTextColor;
	}
	else
	{
		color = singleton.textColor;
	}
	UIFont *font = [UIFont systemFontOfSize:singleton.multiEpgFontSize];
	[color set];

	CGRect curRect;
	CGSize fullHeight;

	// create a mutable copy of the array
	NSMutableArray *events = [_events mutableCopy];

	// add sentinel element to enforce boundaries
	NSObject<EventProtocol> *sentinel = [[GenericEvent alloc] init];
	[events addObject:sentinel];
	sentinel.begin = [begin dateByAddingTimeInterval:multiEpgInterval];

	// remove first element (there has to be at least the sentinel) to set initial values
	NSObject<EventProtocol> *prevEvent = [events objectAtIndex:0];
	[events removeObjectAtIndex:0];
	CGFloat prevX = [prevEvent.begin timeIntervalSinceDate:begin];
	if(prevX < 0)
		prevX = 0;
	else
		prevX *= widthPerSecond;

	// iterate over elements 1 to n+1 while actually working on element i-1 ;)
	for(NSObject<EventProtocol> *event in events)
	{
		// draw left line
		CGContextMoveToPoint(ctx, prevX, 0);
		CGContextAddLineToPoint(ctx, prevX, boundsHeight);

		const CGFloat newX = [event.begin timeIntervalSinceDate:begin] * widthPerSecond;
		curRect = CGRectMake(boundsX + prevX, 0, newX - prevX, boundsHeight);

		// handle current event
		if(prevEvent == self.currentEvent)
		{
			UIImage *currentBgImage = currentEvent ? singleton.multiEpgCurrentBackground : nil;
			UIColor *currentBgColor = currentEvent && !currentBgImage ? singleton.multiEpgCurrentFillColor : nil;
			// draw image
			if(currentBgImage)
			{
				// TODO: any way to optimize this?
				[currentBgImage drawInRect:curRect];
			}
			// fill color
			else
			{
				[currentBgColor setFill];
				CGContextFillRect(ctx, curRect);
			}
		}

		[color setFill];
		fullHeight = [prevEvent.title sizeWithFont:font constrainedToSize:curRect.size lineBreakMode:UILineBreakModeClip];
		curRect = CGRectMake (CGRectGetMidX(curRect) - fullHeight.width / 2.0,
									  CGRectGetMidY(curRect) - fullHeight.height / 2.0,
									  fullHeight.width, fullHeight.height);
		[prevEvent.title drawInRect:curRect withFont:font lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];

		prevX = newX;
		prevEvent = event;
	}
	CGContextStrokePath(ctx);
	if(_secondsSinceBegin > -1 && _secondsSinceBegin < multiEpgInterval)
	{
		const CGFloat xPosNow = (CGFloat)_secondsSinceBegin * widthPerSecond;
		CGContextSetRGBStrokeColor(ctx, 1.0f, 0.0f, 0.0f, 0.8f);
		CGContextSetLineWidth(ctx, 0.4f);
		CGContextMoveToPoint(ctx, xPosNow, 0);
		CGContextAddLineToPoint(ctx, xPosNow, boundsHeight);
		CGContextStrokePath(ctx);
	}

	//[super drawRect:rect];
}

#pragma mark - Accessibility

- (NSArray *)accessibilityElements
{
	if(accessibilityElements)
		return accessibilityElements;

	const UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	const BOOL reverse = (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);

	const CGRect contentRect = self.accessibilityFrame;
	const CGFloat multiEpgInterval = [[NSUserDefaults standardUserDefaults] floatForKey:kMultiEPGInterval];
	CGFloat boundsX, boundsY, boundsHeight, boundsWidth;
	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
		boundsX = contentRect.origin.y;
		boundsY = contentRect.origin.x;
		boundsHeight = contentRect.size.width;
		boundsWidth = contentRect.size.height;
	}
	else
	{
		boundsX = contentRect.origin.x;
		boundsY = contentRect.origin.y;
		boundsHeight = contentRect.size.height;
		boundsWidth = contentRect.size.width;
	}
	const CGFloat widthPerSecond = boundsWidth / multiEpgInterval;
	NSMutableArray *newElements = [NSMutableArray arrayWithCapacity:_events.count];

	// create a mutable copy of the array
	NSMutableArray *events = nil;
	if(reverse)
		events = [NSMutableArray arrayWithArray:[[_events reverseObjectEnumerator] allObjects]];
	else
		events = [_events mutableCopy];

	// create sentinel element to enforce boundaries
	NSObject<EventProtocol> *sentinel = [[GenericEvent alloc] init];
	sentinel.begin = [begin dateByAddingTimeInterval:multiEpgInterval];

	// remove first element (there has to be at least one for us to be called) to set initial values
#if IS_DEBUG()
	NSObject<EventProtocol> *prevEvent = [events objectAtIndex:0];
#else
	NSObject<EventProtocol> *prevEvent = (events.count) ? [events objectAtIndex:0] : nil;
#endif
	CGFloat prevX;
	if(reverse)
	{
		sentinel.end = ((NSObject<EventProtocol> *)[events lastObject]).begin;
		prevX = [prevEvent.end timeIntervalSinceDate:begin] * widthPerSecond;
		if(prevX > boundsWidth)
			prevX = boundsWidth;
	}
	else
	{
		prevX = [prevEvent.begin timeIntervalSinceDate:begin];
		if(prevX < 0)
			prevX = 0;
		else
			prevX *= widthPerSecond;
	}

	// add sentinel to list, remove first element (which we already processed)
	[events addObject:sentinel];
	[events removeObjectAtIndex:0];

	// iterate over elements 1 to n+1 while actually working on element i-1 ;)
	CGRect curRect = CGRectZero;
	for(NSObject<EventProtocol> *event in events)
	{
		CGFloat newX = [(reverse ? event.end : event.begin) timeIntervalSinceDate:begin] * widthPerSecond;
		switch(interfaceOrientation)
		{
			case UIInterfaceOrientationLandscapeRight:
				curRect = CGRectMake(boundsY, boundsX + prevX, boundsHeight, newX - prevX);
				break;
			case UIInterfaceOrientationLandscapeLeft:
				curRect = CGRectMake(boundsY, boundsWidth - prevX, boundsHeight, prevX - newX);
				if(curRect.origin.y + curRect.size.height > boundsWidth) // clip to bounds
					curRect.size.height = boundsWidth - curRect.origin.y;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				curRect = CGRectMake(boundsWidth - prevX, boundsY, prevX - newX, boundsHeight);
				if(curRect.origin.x + curRect.size.width > boundsWidth) // clip to bounds
					curRect.size.width = boundsWidth - curRect.origin.x;
				break;
			default:
				curRect = CGRectMake(boundsX + prevX, boundsY, newX - prevX, boundsHeight);
		}

		MutliEPGAccessibilityElement *acc = [[MutliEPGAccessibilityElement alloc] initWithAccessibilityContainer:self];
		acc.event = prevEvent;
		acc.accessibilityTraits = UIAccessibilityTraitStaticText;
		acc.accessibilityFrame = curRect;

		prevEvent = event;
		prevX = newX;
		[newElements addObject:acc];
	}
	accessibilityElements = newElements;
	return newElements;
}

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSInteger)accessibilityElementCount
{
	return _events.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
	if((NSUInteger)index >= _events.count)
		return nil;
	return [self.accessibilityElements objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return [accessibilityElements indexOfObject:element];
}

@end
