//
//  SwipeTableView.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	swipeTypeNone,
	swipeTypeLeft,
	swipeTypeUp,
	swipeTypeRight,
	swipeTypeDown,
} SwipeType;

@interface SwipeTableView : UITableView
{
@private
	SwipeType _lastSwipe;
	CGPoint _lastTouch;
}

@property (nonatomic) SwipeType lastSwipe;
@property (nonatomic) CGPoint lastTouch;

@end
