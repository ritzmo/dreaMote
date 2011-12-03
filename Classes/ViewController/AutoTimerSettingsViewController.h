//
//  AutoTimerSettingsViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 03.12.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "ReloadableListController.h"

#import <Objects/Generic/AutoTimerSettings.h>

#import <Delegates/AutoTimerSettingsSourceDelegate.h> /* AutoTimerSettingsSourceDelegate */
#import <TableViewCell/CellTextField.h> /* EditableTableViewCellDelegate */

@interface AutoTimerSettingsViewController : ReloadableListController
											<UITextFieldDelegate,
											UITableViewDelegate,
											UITableViewDataSource,
											AutoTimerSettingsSourceDelegate,
											EditableTableViewCellDelegate>
{
@private
	BOOL _shouldSave;

	UITextField *_interval; /*!< @brief Time on service. */
	CellTextField *_intervalCell; /*!< @brief Cell of interval field. */
	UITextField *_maxdays; /*!< @brief Maximum days in the future to check for events. */
	CellTextField *_maxdaysCell; /*!< @brief Cell of maxdays field. */
	UISwitch *_autopoll; /*!< @brief Poll automatically in background. */
	UISwitch *_try_guessing; /*!< @brief . */
	UISwitch *_disabled_on_conflict; /*!< @brief . */
	UISwitch *_addsimilar_on_conflict; /*!< @brief . */
	UISwitch *_show_in_extensionsmenu; /*!< @brief . */
	UISwitch *_fastscan; /*!< @brief . */
	UISwitch *_notifconflict; /*!< @brief . */
	UISwitch *_notifsimilar; /*!< @brief . */
}

@property (nonatomic, strong) AutoTimerSettings *settings;

@property (nonatomic) BOOL willReappear;

@end
