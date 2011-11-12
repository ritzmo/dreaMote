//
//  MultiEPGCellContentView.h
//  dreaMote
//
//  Created by Moritz Venn on 11.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/EventProtocol.h>

@interface MultiEPGCellContentView : UIView
{
@private
	NSArray *_events; /*!< @brief Matching Events. */
	NSMutableArray *_lines; /*!< @brief Positions of vertical Lines. */
	NSTimeInterval _secondsSinceBegin; /*!< @brief Seconds since "_begin". */
	BOOL highlighted;
}

/*!
 @brief Retrieve event at a given point.

 @param point Position of touch.
 @return Event at point or nil if invalid.
 */
- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point;

/*!
 @brief Events.
 */
@property (strong) NSArray *events;

/*!
 @brief Begin of current timeframe.
 */
@property (nonatomic, strong) NSDate *begin;

/*!
 @brief Delayed interval since "begin".
 */
@property (nonatomic, assign) NSTimeInterval secondsSinceBegin;

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@end
