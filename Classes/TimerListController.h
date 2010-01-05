//
//  TimerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/TimerProtocol.h"
#import "TimerSourceDelegate.h"

// Forward Declarations...
@class CXMLDocument;
@class FuzzyDateFormatter;
@class TimerViewController;

/*!
 @brief Timer List.
 
 Lists timers and allows to open a TimerViewController for further information / editing.
 Removing a timer is also allowed.
 
 @note The list is always reloaded when appearing to avoid problems with missing / wrong
 timer ids.
 */
@interface TimerListController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													TimerSourceDelegate>
{
@private
	NSMutableArray *_timers; /*!< @brief Timer List. */
	NSInteger _dist[kTimerStateMax]; /*!< @brief Offset of State in Timer List. */
	FuzzyDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
	TimerViewController *_timerViewController; /*!< @brief Cached Timer Detail View. */
	BOOL _willReappear; /*!< @brief Used to guard free of ressources on close if we are opening a subview. */

	CXMLDocument *_timerXMLDoc; /*!< @brief Current Timer XML Document. */
}

/*!
 @brief Timer List.
 */
@property (nonatomic, retain) NSMutableArray *timers;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
