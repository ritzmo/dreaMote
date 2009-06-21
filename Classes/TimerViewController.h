//
//  TimerViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"
#import "Objects/ServiceProtocol.h"
#import "Objects/TimerProtocol.h"
#import "CellTextField.h"

// Forward declarations...
@class BouquetListController;
@class AfterEventViewController;
@class DatePickerController;
@class SimpleRepeatedViewController;

/*!
 @brief Timer View.
 */
@interface TimerViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													EditableTableViewCellDelegate>
{
@private
	UITextField *timerTitle; /*!< @brief Title Field. */
	CellTextField *timerTitleCell; /*!< @brief Title Cell. */
	UITextField *timerDescription; /*!< @brief Description Field. */
	CellTextField *timerDescriptionCell; /*!< @brief Description Cell. */
	UIButton *timerServiceName; /*!< @brief Service Name Button. */
	UITableViewCell *timerServiceNameCell; /*!< @brief Service Name Cell. */
	UIButton *timerBegin; /*!< @brief Begin Button. */
	UITableViewCell *timerBeginCell; /*!< @brief Begin Cell. */
	UIButton *timerEnd; /*!< @brief End Button. */
	UITableViewCell *timerEndCell; /*!< @brief End Cell. */
	UISwitch *timerEnabled; /*!< @brief Enabled Switch. */
	UISwitch *timerJustplay; /*!< @brief Justplay Switch. */
	UITableViewCell *afterEventCell; /*!< @brief After Event Cell. */
	UITableViewCell *repeatedCell; /*!< @brief Repeated Cell. */
	
	NSObject<TimerProtocol> *_timer; /*!< @brief Associated Timer. */
	NSObject<TimerProtocol> *_oldTimer; /*!< @brief Old Timer when changing existing one. */
	BOOL _creatingNewTimer; /*!< @brief Are we creating a new timer? */
	BOOL _shouldSave; /*!< @brief Should save on exit? */

	BouquetListController *bouquetListController; /*!< @brief Cached Bouquet List. */
	AfterEventViewController *afterEventViewController; /*!< @brief Cached After Event Selector. */
	DatePickerController *datePickerController; /*!< @brief Cached Date Picker. */
	SimpleRepeatedViewController *simpleRepeatedViewController; /*!< @brief Cached Repeated Flags Selector. */
}

/*!
 @brief Open new TimerViewController for given Event.
 
 @param ourEvent Base Event.
 @return TimerViewController instance.
 */
+ (TimerViewController *)withEvent: (NSObject<EventProtocol> *)ourEvent;

/*!
 @brief Open new TimerViewController for given Event and Service.
 
 @param ourEvent Base Event.
 @param ourService Event Service.
 @return TimerViewController instance.
 */
+ (TimerViewController *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService;

/*!
 @brief Open new TimerViewController for given Timer.
 
 @param ourTimer Base Timer.
 @return TimerViewController instance.
 */
+ (TimerViewController *)withTimer: (NSObject<TimerProtocol> *)ourTimer;

/*!
 @brief Open new TimerViewController for new Timer.
 
 @return TimerViewController instance.
 */
+ (TimerViewController *)newTimer;



/*!
 @brief Timer.
 */
@property (nonatomic, retain) NSObject<TimerProtocol> *timer;

/*!
 @brief Old Timer if editing existing one.
 */
@property (nonatomic, retain) NSObject<TimerProtocol> *oldTimer;

/*!
 @brief Are we creating a new Timer?
 */
@property (assign) BOOL creatingNewTimer;

@end
