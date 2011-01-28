//
//  SwipeTableView.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SwipeTableView.h"

#define SWIPE_MIN_DISPLACEMENT 10.0

@implementation SwipeTableView

@synthesize lastSwipe = _lastSwipe;
@synthesize lastTouch = _lastTouch;

/* started touch */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	const UITouch *touch = [[event allTouches] anyObject];
	_lastTouch = [touch locationInView: self];
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
	const UITouch *touch = [[event allTouches] anyObject];
	const CGPoint location = [touch locationInView: self];
	const CGFloat xDisplacement = location.x - _lastTouch.x;
	const CGFloat yDisplacement = location.y - _lastTouch.y;
	const CGFloat xDisplacementAbs = (CGFloat)fabs(xDisplacement);
	const CGFloat yDisplacementAbs = (CGFloat)fabs(yDisplacement);

	// horizontal swipe
	if(xDisplacementAbs > yDisplacementAbs)
	{
		if(xDisplacementAbs > SWIPE_MIN_DISPLACEMENT)
		{
			if(xDisplacement > 0.0)
				_lastSwipe = swipeTypeRight;
			else
				_lastSwipe = swipeTypeLeft;
		}
	}
	// vertical swipe
	else
	{
		if(yDisplacementAbs > SWIPE_MIN_DISPLACEMENT)
		{
			if(yDisplacement > 0.0)
				_lastSwipe = swipeTypeDown;
			else
				_lastSwipe = swipeTypeUp;
		}
	}
	[super touchesEnded:touches withEvent:event];
}

@end
