//
//  TimerViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h" /* EventProtocol */
#import "Objects/ServiceProtocol.h" /* ServiceProtocol */
#import "Objects/TimerProtocol.h" /* TimerProtocol */
#import "CellTextField.h" /* CellTextField */

#import "AfterEventViewController.h" /* AfterEventDelegate */
#import "LocationListController.h" /* LocationListDelegate */
#import "ServiceListController.h" /* ServiceListDelegate */
#import "SimpleRepeatedViewController.h" /* SimpleRepeatedDelegate */

// Forward declarations...
@class DatePickerController;

/*!
 @brief Timer View.
 
 Display further information about a timer and allow to edit its configuration.
 */
@interface TimerViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													ServiceListDelegate, AfterEventDelegate,
													SimpleRepeatedDelegate, LocationListDelegate,
													EditableTableViewCellDelegate,
													UIPopoverControllerDelegate,
													UISplitViewControllerDelegate>
{
@private
	UIPopoverController *popoverController;
	UIBarButtonItem *_cancelButtonItem;
	UIBarButtonItem *_popoverButtonItem;

	UITextField *_timerTitle; /*!< @brief Title Field. */
	CellTextField *_timerTitleCell; /*!< @brief Title Cell. */
	UITextField *_timerDescription; /*!< @brief Description Field. */
	CellTextField *_timerDescriptionCell; /*!< @brief Description Cell. */
	UITableViewCell *_timerServiceNameCell; /*!< @brief Service Name Cell. */
	UITableViewCell *_timerBeginCell; /*!< @brief Begin Cell. */
	UITableViewCell *_timerEndCell; /*!< @brief End Cell. */
	UISwitch *_timerEnabled; /*!< @brief Enabled Switch. */
	UISwitch *_timerJustplay; /*!< @brief Justplay Switch. */
	UITableViewCell *_afterEventCell; /*!< @brief After Event Cell. */
	UITableViewCell *_locationCell; /*!< @brief Location Cell. */
	UITableViewCell *_repeatedCell; /*!< @brief Repeated Cell. */
	
	NSObject<TimerProtocol> *_timer; /*!< @brief Associated Timer. */
	NSObject<TimerProtocol> *_oldTimer; /*!< @brief Old Timer when changing existing one. */
	BOOL _creatingNewTimer; /*!< @brief Are we creating a new timer? */
	BOOL _shouldSave; /*!< @brief Should save on exit? */

	UIViewController *_afterEventNavigationController; /*!< @brief Navigation Controller of After Event Selector. */
	AfterEventViewController *_afterEventViewController; /*!< @brief Cached After Event Selector. */
	UIViewController *_bouquetListController; /*!< @brief Cached Bouquet List. */
	UINavigationController *_datePickerNavigationController; /*!< @brief Navigation Controller of Date Picker. */
	DatePickerController *_datePickerController; /*!< @brief Cached Date Picker. */
	UIViewController *_locationListController; /*!< @brief Cached Location List. */
	UIViewController *_simpleRepeatedNavigationController; /*!< @brief Navigation Controller of _simpleRepeatedViewController */
	SimpleRepeatedViewController *_simpleRepeatedViewController; /*!< @brief Cached Repeated Flags Selector. */
}

/*!
 @brief Open new TimerViewController for given Event.
 
 @param ourEvent Base Event.
 @return TimerViewController instance.
 */
+ (TimerViewController *)newWithEvent: (NSObject<EventProtocol> *)ourEvent;

/*!
 @brief Open new TimerViewController for given Event and Service.
 
 @param ourEvent Base Event.
 @param ourService Event Service.
 @return TimerViewController instance.
 */
+ (TimerViewController *)newWithEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService;

/*!
 @brief Open new TimerViewController for given Timer.
 
 @param ourTimer Base Timer.
 @return TimerViewController instance.
 */
+ (TimerViewController *)newWithTimer: (NSObject<TimerProtocol> *)ourTimer;

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
