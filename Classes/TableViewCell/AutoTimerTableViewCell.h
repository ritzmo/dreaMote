//
//  AutoTimerTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 10.04.10.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TableViewCell/BaseTableViewCell.h>
#import <Objects/Generic/AutoTimer.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kAutoTimerCell_ID;

/*!
 @brief UITableViewCell optimized to display AutoTimers.
 */
@interface AutoTimerTableViewCell : BaseTableViewCell
{
@private	
	AutoTimer *_timer; /*!< @brief Timer. */
	UILabel *_timerNameLabel; /*!< @brief Name Label. */
}

/*!
 @brief AutoTimer.
 */
@property (nonatomic, strong) AutoTimer *timer;

@end
