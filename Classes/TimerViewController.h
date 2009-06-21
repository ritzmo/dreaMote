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
	UITextField *_timerTitle; /*!< @brief Title Field. */
	CellTextField *_timerTitleCell; /*!< @brief Title Cell. */
	UITextField *_timerDescription; /*!< @brief Description Field. */
	CellTextField *_timerDescriptionCell; /*!< @brief Description Cell. */
	UIButton *_timerServiceName; /*!< @brief Service Name Button. */
	UITableViewCell *_timerServiceNameCell; /*!< @brief Service Name Cell. */
	UIButton *_timerBegin; /*!< @brief Begin Button. */
	UITableViewCell *_timerBeginCell; /*!< @brief Begin Cell. */
	UIButton *_timerEnd; /*!< @brief End Button. */
	UITableViewCell *_timerEndCell; /*!< @brief End Cell. */
	UISwitch *_timerEnabled; /*!< @brief Enabled Switch. */
	UISwitch *_timerJustplay; /*!< @brief Justplay Switch. */
	UITableViewCell *_afterEventCell; /*!< @brief After Event Cell. */
	UITableViewCell *_repeatedCell; /*!< @brief Repeated Cell. */
	
	NSObject<TimerProtocol> *_timer; /*!< @brief Associated Timer. */
	NSObject<TimerProtocol> *_oldTimer; /*!< @brief Old Timer when changing existing one. */
	BOOL _creatingNewTimer; /*!< @brief Are we creating a new timer? */
	BOOL _shouldSave; /*!< @brief Should save on exit? */

	BouquetListController *_bouquetListController; /*!< @brief Cached Bouquet List. */
	AfterEventViewController *_afterEventViewController; /*!< @brief Cached After Event Selector. */
	DatePickerController *_datePickerController; /*!< @brief Cached Date Picker. */
	SimpleRepeatedViewController *_simpleRepeatedViewController; /*!< @brief Cached Repeated Flags Selector. */
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
