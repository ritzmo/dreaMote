//
//  TimerTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/TimerProtocol.h>

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
}

/*!
 @brief Timer.
 */
@property (nonatomic, strong) NSObject<TimerProtocol> *timer;

/*!
 @brief Date Formatter instance.
 */
@property (nonatomic, strong) NSDateFormatter *formatter;

@end
