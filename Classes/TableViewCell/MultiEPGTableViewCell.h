//
//  MultiEPGTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/ServiceProtocol.h"
#import "Objects/EventProtocol.h"

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kMultiEPGCell_ID;

/*!
 @brief UITableViewCell optimized to display vertical 1-Service/x-Events combination.
 */
@interface MultiEPGTableViewCell : UITableViewCell
{
@private	
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
	NSArray *_events; /*!< @brief Matching Events. */
	NSMutableArray *_lines; /*!< @brief Positions of vertical Lines. */
	UILabel *_serviceNameLabel; /*!< @brief Servicename Label. */
	NSTimeInterval _secondsSinceBegin; /*!< @brief Seconds since "_begin". */
}

/*!
 @brief Retrieve event at a given point.
 
 @param point Position of touch.
 @return Event at point or nil if invalid.
 */
- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point;

/*!
 @brief Service.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> *service;

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

@end