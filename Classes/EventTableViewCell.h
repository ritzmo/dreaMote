//
//  EventTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/EventProtocol.h"

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kEventCell_ID;

/*!
 @brief UITableViewCell optimized to display Events.
 */
@interface EventTableViewCell : UITableViewCell
{
@private	
	NSObject<EventProtocol> *_event; /*!< @brief Assigned Event. */
	UILabel *_eventNameLabel; /*!< @brief Name Label. */
	UILabel *_eventTimeLabel; /*!< @brief Time Label. */
	UILabel *_eventServiceLabel; /*!< @brief Service Label. */
	NSDateFormatter *_formatter; /*!< @brief Date Formatter instance. */
	BOOL _showService; /*!< @brief Display service name? */
}

/*!
 @brief Event.
 */
@property (nonatomic, retain) NSObject<EventProtocol> *event;

/*!
 @brief Name Label.
 */
@property (nonatomic, retain) UILabel *eventNameLabel;

/*!
 @brief Time Label.
 */
@property (nonatomic, retain) UILabel *eventTimeLabel;

/*!
 @brief Service name label.
 */
@property (nonatomic, retain) UILabel *eventServiceLabel;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) NSDateFormatter *formatter;

/*!
 @brief Display service name?
 
 @note This needs to be set before assigning a new event to work properly.
 Also the Events needs to keep a copy of the service.
 */
@property (nonatomic, assign) BOOL showService;

@end
