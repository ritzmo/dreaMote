//
//  SimulatedTimerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright 2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"
#import "TimerSourceDelegate.h" /* TimerSourceDelegate */

/*!
 @brief Simulated Timer List.
 */
@interface SimulatedTimerListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															TimerSourceDelegate>
{
@private
	NSMutableArray *_timers; /*!< @brief SimulatedTimer List. */
	UIBarButtonItem *_sortButton; /*!< @brief Sort Button. */
	BOOL _sortTitle; /*!< @brief Sort by title? */
}

/*!
 @brief Is this view slave to a split view?
 */
@property (nonatomic) BOOL isSlave;

@end
