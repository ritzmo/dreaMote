//
//  AutoTimerViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.03.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/ServiceProtocol.h> /* ServiceProtocol */
#import <Objects/Generic/AutoTimer.h> /* TimerProtocol */
#import "CellTextField.h" /* CellTextField */

#import "AfterEventViewController.h" /* AfterEventDelegate */
#import "AutoTimerSettingsSourceDelegate.h" /* AutoTimerSettingsSourceDelegate */
#import "BouquetListController.h" /* BouquetListDelegate */
#import "ServiceListController.h" /* ServiceListDelegate */
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */

// Forward declarations...
@protocol AutoTimerViewDelegate;

/*!
 @brief AutoTimer View.
 
 Display further information about an AutoTimer and allow to edit its configuration.
 */
@interface AutoTimerViewController : UIViewController <UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													ServiceListDelegate, BouquetListDelegate,
													AfterEventDelegate,
													AutoTimerSettingsSourceDelegate,
													EditableTableViewCellDelegate,
													UIPopoverControllerDelegate,
													MGSplitViewControllerDelegate>
{
@private
	UIPopoverController *popoverController;
	UIBarButtonItem *_cancelButtonItem;
	UIBarButtonItem *_popoverButtonItem;
	UITableView *_tableView;

	AutoTimer *_timer; /*!< @brief Associated AutoTimer. */
	BOOL _creatingNewTimer; /*!< @brief Are we creating a new timer? */
	BOOL _shouldSave; /*!< @brief Should save on exit? */
	NSDateFormatter *_dateFormatter; /*!< @brief Date formatter. */

	CellTextField *_titleCell; /*!< @brief Cell for Title. */
	UITextField *_titleField; /*!< @brief Textfield for Title. */
	CellTextField *_matchCell; /*!< @brief Cell for Match. */
	UITextField *_matchField; /*!< @brief Textfield for Match. */
	CellTextField *_maxdurationCell; /*!< @brief Cell for Maxduration. */
	UITextField *_maxdurationField; /*!< @brief Textfield for Maxduration. */
	UISwitch *_timerEnabled; /*!< @brief Enable/Disable Switch. */
	UISwitch *_sensitiveSearch; /*!< @brief Case-(in)sensitive Search. */
	UISwitch *_overrideAlternatives; /*!< @brief Override Alternatives? */
	UISwitch *_afterEventTimespanSwitch; /*!< @brief AfterEvent only during timespan? */
	UISwitch *_timeframeSwitch; /*!< @brief Enable/Disable Timeframe. */
	UISwitch *_timerJustplay; /*!< @brief Create zap timers? */
	UISwitch *_timerSetEndtime; /*!< @brief Set Endtime for zap timers? */
	UISwitch *_timespanSwitch; /*!< @brief Enable/Disable Timespan. */
	UISwitch *_maxdurationSwitch; /*!< @brief Maxduration Switch. */
	UISwitch *_vpsEnabledSwitch; /*!< @brief Enable/Disable VPS. */
	UISwitch *_vpsOverwriteSwitch; /*!< @brief Let VPS/channel control recordings. */

	UIViewController *_afterEventNavigationController; /*!< @brief Navigation Controller of After Event Selector. */
	AfterEventViewController *_afterEventViewController; /*!< @brief Cached After Event Selector. */
	UIViewController *_bouquetListController; /*!< @brief Cached Bouquet List. */
	UIViewController *_serviceListController; /*!< @brief Cached Service List. */
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
 @brief Start loading the settings.

 Needed when being shown from a view other than the AutoTimerList because
 then we don't know which version of the AutoTimer is installed and in
 effect do not know which features to show.
 @note This actually gives us more information than the list gives us,
 so properly process them in a future version and also incorporate them
 when shown from the AutoTimerList.
 */
- (void)loadSettings;

/*!
 @brief Set only the AutoTimer-Version.

 Used as helper method for "broken" AutoTimer-Versions without actual settings.
*/
- (void)setAutotimerVersion:(NSInteger)version;



/*!
 @brief AutoTimer.
 */
@property (nonatomic, strong) AutoTimer *timer;

/*!
 @brief Are we creating a new AutoTimer?
 */
@property (assign) BOOL creatingNewTimer;

/*!
 @brief AutoTimer Settings.
 @note Used to hide/show some features.
 */
@property (nonatomic, strong) AutoTimerSettings *autotimerSettings;

/*!
 @brief Delegate.
 */
@property (nonatomic, unsafe_unretained) NSObject<AutoTimerViewDelegate> *delegate;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end



@protocol AutoTimerViewDelegate
/*!
 @brief An AutoTimer was added successfully.

 @param tvc AutoTimerViewController instance
 @param at AutoTimer that was added
 */
- (void)autoTimerViewController:(AutoTimerViewController *)tvc timerWasAdded:(AutoTimer *)at;

/*!
 @brief Timer was changed successfully.

 @param tvc AutoTimerViewController instance
 @param at Modified AutoTimer
 */
- (void)autoTimerViewController:(AutoTimerViewController *)tvc timerWasEdited:(AutoTimer *)at;

/*
 @brief Editing was canceled.

 @param tvc AutoTimerViewController instance
 @param at AutoTimer that was supposed to be changed
 */
- (void)autoTimerViewController:(AutoTimerViewController *)tvc editingWasCanceled:(AutoTimer *)at;
@end
