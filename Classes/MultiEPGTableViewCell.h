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
	NSArray *_lines; /*!< @brief Positions of vertical Lines. */
	NSDate *_begin; /*!< @brief Begin of currently displayed timeframe. */
	UILabel *_serviceNameLabel; /*!< @brief Servicename Label. */
}

/*!
 @brief Servicename Label.
 */
@property (nonatomic, retain) UILabel *serviceNameLabel;

/*!
 @brief Service.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

/*!
 @brief Events.
 */
@property (nonatomic, retain) NSArray *events;

/*!
 @brief Begin of current timeframe.
 */
@property (nonatomic, retain) NSDate *begin;

@end