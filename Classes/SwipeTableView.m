//
//  SwipeTableView.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SwipeTableView.h"

#define SWIPE_MIN_DISPLACEMENT 10.0

@interface SwipeTableView()
@property (nonatomic, retain) UIEvent *lastEvent;
@end

@implementation SwipeTableView

@synthesize lastEvent = _lastEvent;
@synthesize lastSwipe = _lastSwipe;
@synthesize lastTouch = _lastTouch;

- (void)dealloc
{
	[_lastEvent release];

	[super dealloc];
}

/* started touch */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	const UITouch *touch = [[event allTouches] anyObject];
	_lastTouch = [touch locationInView: self];
	_lastSwipe = swipeTypeNone;
	self.lastEvent = nil;
	[super touchesBegan:touches withEvent:event];
}

/* cancel touch */
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	_lastTouch = CGPointZero;
	_lastSwipe = swipeTypeNone;
	[super touchesCancelled:touches withEvent:event];
}

/* finished touch */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	const UITouch *touch = [touches anyObject];
	const CGPoint location = [touch locationInView: self];
	const CGFloat xDisplacement = location.x - _lastTouch.x;
	const CGFloat yDisplacement = location.y - _lastTouch.y;
	const CGFloat xDisplacementAbs = (CGFloat)fabs(xDisplacement);
	const CGFloat yDisplacementAbs = (CGFloat)fabs(yDisplacement);

	// we already handled this event
	if(_lastEvent == event)
	{
		[super touchesEnded:touches withEvent:event];
		return;
	}
	else self.lastEvent = event;

	switch([[event allTouches] count])
	{
		case 1:
			_lastSwipe = oneFinger;
			break;
		case 2:
			_lastSwipe = twoFingers;
			break;
		case 3:
			_lastSwipe = threeFingers;
			break;
		default:
			_lastSwipe = swipeTypeNone; // huh?
			break;
	}

	// horizontal swipe
	if(xDisplacementAbs > yDisplacementAbs)
	{
		if(xDisplacementAbs > SWIPE_MIN_DISPLACEMENT)
		{
			if(xDisplacement > 0.0)
				_lastSwipe |= swipeTypeRight;
			else
				_lastSwipe |= swipeTypeLeft;

			if([self.delegate conformsToProtocol:@protocol(SwipeTableViewDelegate)])
			{
				NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
				[(NSObject<SwipeTableViewDelegate> *)self.delegate tableView:self didSwipeRowAtIndexPath:indexPath];
				[super touchesEnded:nil withEvent:nil]; // prevent delegate calls
				return;
			}
		}
	}
#if 0
	// vertical swipe
	else
	{
		if(yDisplacementAbs > SWIPE_MIN_DISPLACEMENT)
		{
			if(yDisplacement > 0.0)
				_lastSwipe |= swipeTypeDown;
			else
				_lastSwipe |= swipeTypeUp;
		}
	}
#endif
	[super touchesEnded:touches withEvent:event];
}

@end
