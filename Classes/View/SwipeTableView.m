//
//  SwipeTableView.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SwipeTableView.h"

#import "UIDevice+SystemVersion.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define SWIPE_MIN_DISPLACEMENT 10.0

@interface SwipeTableView()
@property (nonatomic, retain) UIEvent *lastEvent;
- (void)swipeLeftAction:(UISwipeGestureRecognizer *)gesture;
- (void)swipeRightAction:(UISwipeGestureRecognizer *)gesture;
@end

static void touchesBegan(SwipeTableView* self, SEL _cmd, NSSet* touches, UIEvent *event);
static void touchesCancelled(SwipeTableView* self, SEL _cmd, NSSet* touches, UIEvent *event);
static void touchesEnded(SwipeTableView* self, SEL _cmd, NSSet* touches, UIEvent *event);

@implementation SwipeTableView

@synthesize lastEvent = _lastEvent;
@synthesize lastSwipe = _lastSwipe;
@synthesize lastTouch = _lastTouch;

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
	if((self = [super initWithFrame:frame style:style]))
	{
		const BOOL newerThan32 = [UIDevice newerThanIos:3.2f];
		if(newerThan32)
		{
			UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftAction:)];
			swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
			[self addGestureRecognizer:swipeGesture];
			[swipeGesture release];

			swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightAction:)];
			swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
			[self addGestureRecognizer:swipeGesture];
			[swipeGesture release];
		}
		else
		{
			static BOOL initialized = NO;

			// use old manual detection on iOS older than 3.2 (without gesture recognizer)
			if(!initialized)
			{
				// using the meta class does not work, even though it gets resolved to SwipeTableView?!
				id selfMetaClass = /*objc_getMetaClass(class_getName*/(([self class]));
				class_addMethod(selfMetaClass, @selector(touchesBegan:withEvent:), (IMP)touchesBegan, "v@:@@");
				class_addMethod(selfMetaClass, @selector(touchesCancelled:withEvent:), (IMP)touchesCancelled, "v@:@@");
				class_addMethod(selfMetaClass, @selector(touchesEnded:withEvent:), (IMP)touchesEnded, "v@:@@");
			}
			initialized = YES;
		}
	}

	return self;
}

- (void)dealloc
{
	[_lastEvent release];

	[super dealloc];
}

#pragma mark - iOS 3.2+

- (void)swipeAction:(UISwipeGestureRecognizer *)gesture
{
	const CGPoint location = [gesture locationOfTouch:0 inView:self];
	self.lastTouch = location;

	if([self.delegate conformsToProtocol:@protocol(SwipeTableViewDelegate)])
	{
		NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
		if(indexPath)
		{
			[(NSObject<SwipeTableViewDelegate> *)self.delegate tableView:self didSwipeRowAtIndexPath:indexPath];
		}
	}
}

- (void)swipeLeftAction:(UISwipeGestureRecognizer *)gesture
{
	_lastSwipe = oneFinger;
	_lastSwipe |= swipeTypeLeft;
	[self swipeAction:gesture];
}

- (void)swipeRightAction:(UISwipeGestureRecognizer *)gesture
{
	_lastSwipe = oneFinger;
	_lastSwipe |= swipeTypeRight;
	[self swipeAction:gesture];
}

#pragma mark - iOS 3.1 or older

/* started touch */
static void touchesBegan(SwipeTableView* self, SEL _cmd, NSSet* touches, UIEvent *event)
{
	const UITouch *touch = [[event allTouches] anyObject];
	self.lastTouch = [touch locationInView: self];
	self.lastSwipe = swipeTypeNone;
	self.lastEvent = nil;

	struct objc_super super;
	super.super_class = [self superclass];
	super.receiver = self;
	objc_msgSendSuper(&super, _cmd, touches, event);
}

/* cancel touch */
static void touchesCancelled(SwipeTableView* self, SEL _cmd, NSSet* touches, UIEvent *event)
{
	self.lastTouch = CGPointZero;
	self.lastSwipe = swipeTypeNone;

	struct objc_super super;
	super.super_class = [self superclass];
	super.receiver = self;
	objc_msgSendSuper(&super, _cmd, touches, event);
}

/* finished touch */
static void touchesEnded(SwipeTableView* self, SEL _cmd, NSSet* touches, UIEvent *event)
{
	SwipeType _lastSwipe = swipeTypeNone;
	CGPoint _lastTouch = self.lastTouch;

	const UITouch *touch = [touches anyObject];
	const CGPoint location = [touch locationInView: self];
	const CGFloat xDisplacement = location.x - _lastTouch.x;
	const CGFloat yDisplacement = location.y - _lastTouch.y;
	const CGFloat xDisplacementAbs = (CGFloat)fabs(xDisplacement);
	const CGFloat yDisplacementAbs = (CGFloat)fabs(yDisplacement);

	// we already handled this event
	if(self.lastEvent == event)
	{
		goto touchesEnded_out;
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
			self.lastSwipe = _lastSwipe;

			if([self.delegate conformsToProtocol:@protocol(SwipeTableViewDelegate)])
			{
				NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
				if(indexPath)
				{
					[(NSObject<SwipeTableViewDelegate> *)self.delegate tableView:self didSwipeRowAtIndexPath:indexPath];
					touches = nil; // prevent delegate calls
					event = nil;
					goto touchesEnded_out;
				}
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
			self.lastSwipe = _lastSwipe;

			if([self.delegate conformsToProtocol:@protocol(SwipeTableViewDelegate)])
			{
				NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
				if(indexPath)
				{
					[(NSObject<SwipeTableViewDelegate> *)self.delegate tableView:self didSwipeRowAtIndexPath:indexPath];
					touches = nil; // prevent delegate calls
					event = nil;
					goto touchesEnded_out;
				}
			}
		}
	}
#endif

touchesEnded_out:
	self.lastSwipe = _lastSwipe;
	struct objc_super super;
	super.super_class = [self superclass];
	super.receiver = self;
	objc_msgSendSuper(&super, _cmd, touches, event);
}

@end
