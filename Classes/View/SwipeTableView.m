//
//  SwipeTableView.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "SwipeTableView.h"

@interface SwipeTableView()
- (void)swipeLeftAction:(UISwipeGestureRecognizer *)gesture;
- (void)swipeRightAction:(UISwipeGestureRecognizer *)gesture;
@end

@implementation SwipeTableView

@synthesize lastSwipe, lastTouch;

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
	if((self = [super initWithFrame:frame style:style]))
	{
		needsInit = YES;
	}
	return self;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
	// only add gesture recognizers of delegate conforms to our protocol
	// prevents side-effects like not working "swipe to delete" since cancelsTouchesInView = NO does not
	// appear to take care of that
	if(needsInit && [delegate conformsToProtocol:@protocol(SwipeTableViewDelegate)])
	{
		needsInit = NO;

		UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftAction:)];
		swipeGesture.cancelsTouchesInView = NO;
		swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
		[self addGestureRecognizer:swipeGesture];

		swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightAction:)];
		swipeGesture.cancelsTouchesInView = NO;
		swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
		[self addGestureRecognizer:swipeGesture];
	}
	[super setDelegate:delegate];
}

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
	lastSwipe = oneFinger;
	lastSwipe |= swipeTypeLeft;
	[self swipeAction:gesture];
}

- (void)swipeRightAction:(UISwipeGestureRecognizer *)gesture
{
	lastSwipe = oneFinger;
	lastSwipe |= swipeTypeRight;
	[self swipeAction:gesture];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	const UITouch *touch = [[event allTouches] anyObject];
	lastTouch = [touch locationInView: self];
	lastSwipe = swipeTypeNone;

	[super touchesBegan:touches withEvent:event];
}

@end
