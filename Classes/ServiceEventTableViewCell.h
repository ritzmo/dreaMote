//
//  ServiceEventTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kServiceEventCell_ID;

/*!
 @brief UITableViewCell optimized to display Service/Now/Next combination.
 */
@interface ServiceEventTableViewCell : UITableViewCell
{
@private
	NSObject<EventProtocol> *_now; /*!< @brief Current event. */
	UILabel *_serviceNameLabel; /*!< @brief Name Label. */
	UILabel *_nowLabel; /*!< @brief Current Event Label. */
	UILabel *_nowTimeLabel; /*!< @brief Current Event Time Label. */
	UILabel *_nextLabel; /*!< @brief Next Event Label. */
	UILabel *_nextTimeLabel; /*!< @brief Current Event Time Label. */
	NSDateFormatter *_formatter; /*!< @brief Date Formatter instance. */
}

/*!
 @brief Set text of next label by event.
 
 @param new Event to use.
 */
- (void)setNext:(NSObject <EventProtocol>*)new;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) NSDateFormatter *formatter;

/*!
 @brief Name Label.
 */
@property (nonatomic, retain) UILabel *serviceNameLabel;

/*!
 @brief Current Event.
 */
@property (nonatomic, retain) NSObject<EventProtocol> *now;

@end

