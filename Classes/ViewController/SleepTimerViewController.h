//
//  SleepTimerViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"

#import "CellTextField.h" /* EditableTableViewCellDelegate */
#import "SleepTimerSourceDelegate.h" /* SleepTimerSourceDelegate */

// Forward declarations...
@class DatePickerController;

/*!
 @brief EPGRefresh View.

 Display EPGRefresh settings & services and allow to commit changes.
 */
@interface SleepTimerViewController : ReloadableListController <UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													EditableTableViewCellDelegate,
													SleepTimerSourceDelegate>
{
@private
	UIBarButtonItem *_cancelButtonItem;

	BOOL _shouldSave; /*!< @brief Should save on exit? */
	BOOL _expectReturn; /*!< @brief We commited changed and are waiting for the result. */
	SleepTimer *settings; /*!< @brief SleepTimer settings. */

	UITextField *_time; /*!< @brief Duration of SleepTimer. */
	CellTextField *_timeCell; /*!< @brief Cell of duration field. */
	UISwitch *_enabled; /*!< @brief Enabled Switch. */
	UISwitch *_shutdown; /*!< @brief Shutdown/Standby switch. */
}

@end
