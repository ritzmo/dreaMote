//
//  AutoTimerViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/ServiceProtocol.h" /* ServiceProtocol */
#import "Objects/Generic/AutoTimer.h" /* TimerProtocol */
#import "CellTextField.h" /* CellTextField */

#import "AfterEventViewController.h" /* AfterEventDelegate */
#import "LocationListController.h" /* LocationListDelegate */
#import "ServiceListController.h" /* ServiceListDelegate */
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */

// Forward declarations...
@class DatePickerController;
@protocol AutoTimerViewDelegate;

/*!
 @brief AutoTimer View.
 
 Display further information about an AutoTimer and allow to edit its configuration.
 */
@interface AutoTimerViewController : UIViewController <UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													ServiceListDelegate, AfterEventDelegate,
													LocationListDelegate,
													EditableTableViewCellDelegate,
													UIPopoverControllerDelegate,
													MGSplitViewControllerDelegate>
{
@private
	UIPopoverController *popoverController;
	UIBarButtonItem *_cancelButtonItem;
	UIBarButtonItem *_popoverButtonItem;

	NSObject<AutoTimerViewDelegate> *_delegate; /*!< @brief Delegate. */
	AutoTimer *_timer; /*!< @brief Associated AutoTimer. */
	BOOL _creatingNewTimer; /*!< @brief Are we creating a new timer? */
	BOOL _shouldSave; /*!< @brief Should save on exit? */

	UITextField *_titleField; /*!< @brief Textfield for Title. */
	UITextField *_matchField; /*!< @brief Textfield for Match. */
	UITextField *_maxdurationField; /*!< @brief Textfield for Maxduration. */
	UISwitch *_timerEnabled; /*!< @brief Enable/Disable Switch. */
	UISwitch *_exactSearch; /*!< @brief Exact/Partial Search. */
	UISwitch *_sensitiveSearch; /*!< @brief Case-(in)sensitive Search. */
	UISwitch *_overrideAlternatives; /*!< @brief Override Alternatives? */
	UISwitch *_timerJustplay; /*!< @brief Create zap timers? */
	UISwitch *_avoidDuplicateDescription; /*!< @brief Avoid duplicate description? */
	UISwitch *_maxdurationSwitch; /*!< @brief Maxduration Switch. */

	UIViewController *_afterEventNavigationController; /*!< @brief Navigation Controller of After Event Selector. */
	AfterEventViewController *_afterEventViewController; /*!< @brief Cached After Event Selector. */
	UIViewController *_bouquetListController; /*!< @brief Cached Bouquet List. */
	UINavigationController *_datePickerNavigationController; /*!< @brief Navigation Controller of Date Picker. */
	DatePickerController *_datePickerController; /*!< @brief Cached Date Picker. */
	UIViewController *_locationListController; /*!< @brief Cached Location List. */
}

/*!
 @brief Open new AutoTimerViewController for given AutoTimer.
 
 @param ourTimer Base AutoTimer.
 @return AutoTimerViewController instance.
 */
+ (AutoTimerViewController *)newWithAutoTimer: (AutoTimer *)ourTimer;

/*!
 @brief Open new AutoTimerViewController for new AutoTimer.
 
 @return AutoTimerViewController instance.
 */
+ (AutoTimerViewController *)newAutoTimer;



/*!
 @brief AutoTimer.
 */
@property (nonatomic, retain) AutoTimer *timer;

/*!
 @brief Are we creating a new AutoTimer?
 */
@property (assign) BOOL creatingNewTimer;

/*!
 @brief Delegate.
 */
@property (nonatomic, retain) NSObject<AutoTimerViewDelegate> *delegate;

@end



@protocol AutoTimerViewDelegate
/*!
 @brief An AutoTimer was added successfully.

 @param tvc AutoTimerViewController instance
 @param at AutoTimer that was added
 */
- (void)AutoTimerViewController:(AutoTimerViewController *)tvc timerWasAdded:(AutoTimer *)at;

/*!
 @brief Timer was changed successfully.

 @param tvc AutoTimerViewController instance
 @param at Modified AutoTimer
 */
- (void)AutoTimerViewController:(AutoTimerViewController *)tvc timerWasEdited:(AutoTimer *)at;

/*
 @brief Editing was canceled.

 @param tvc AutoTimerViewController instance
 @param at AutoTimer that was supposed to be changed
 */
- (void)AutoTimerViewController:(AutoTimerViewController *)tvc editingWasCanceled:(AutoTimer *)at;
@end
