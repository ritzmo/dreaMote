//
//  EventTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/EventProtocol.h"

#import "FuzzyDateFormatter.h"

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
	FuzzyDateFormatter *_formatter; /*!< @brief Date Formatter instance. */
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
 @brief Date Formatter.
 */
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end
