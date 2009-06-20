//
//  TimerTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/TimerProtocol.h"

#import "FuzzyDateFormatter.h"

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kTimerCell_ID;

/*!
 @brief UITableViewCell optimized to display Timers.
 */
@interface TimerTableViewCell : UITableViewCell
{
@private	
	NSObject<TimerProtocol> *_timer; /*!< @brief Timer. */
	UILabel *_serviceNameLabel; /*!< @brief Service Label. */
	UILabel *_timerNameLabel; /*!< @brief Name Label. */
	UILabel *_timerTimeLabel; /*!< @brief Time Label. */
	FuzzyDateFormatter *_formatter; /*!< @brief Date Formatter instance. */
}

/*!
 @brief Timer.
 */
@property (nonatomic, retain) NSObject<TimerProtocol> *timer;

/*!
 @brief Service Label.
 */
@property (nonatomic, retain) UILabel *serviceNameLabel;

/*!
 @brief Name Label.
 */
@property (nonatomic, retain) UILabel *timerNameLabel;

/*!
 @brief Time Label.
 */
@property (nonatomic, retain) UILabel *timerTimeLabel;

/*!
 @brief Date Formatter instance.
 */
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end
