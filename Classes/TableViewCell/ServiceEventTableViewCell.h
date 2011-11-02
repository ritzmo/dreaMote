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
	NSObject<EventProtocol> *_next; /*!< @brief Next event. */
	UILabel *_serviceNameLabel; /*!< @brief Name Label. */
	UILabel *_nowLabel; /*!< @brief Current Event Label. */
	UILabel *_nowTimeLabel; /*!< @brief Current Event Time Label. */
	UILabel *_nextLabel; /*!< @brief Next Event Label. */
	UILabel *_nextTimeLabel; /*!< @brief Current Event Time Label. */
	NSInteger timeWidth;
}

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *formatter;

/*!
 @brief Load Picons internally?
 When showing a large ammount of services (e.g. in the Service List) loading the picons can make
 the UI respond slowly to user interaction. By factoring out the loading code into a background
 thread the parent view can control this.
 */
@property (nonatomic, assign) BOOL loadPicon;

/*!
 @brief Current Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *now;

/*!
 @brief Next Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *next;

@end

