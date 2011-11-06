//
//  EPGRefreshViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"

#import "BouquetListController.h" /* BouquetListDelegate */
#import "CellTextField.h" /* EditableTableViewCellDelegate */
#import "EPGRefreshSettingsSourceDelegate.h" /* EPGRefreshSettingsSourceDelegate */
#import "ServiceListController.h" /* ServiceListDelegate */
#import "ServiceSourceDelegate.h" /* ServiceSourceDelegate */

// Forward declarations...
@class DatePickerController;

/*!
 @brief EPGRefresh View.

 Display EPGRefresh settings & services and allow to commit changes.
 */
@interface EPGRefreshViewController : ReloadableListController <UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													ServiceListDelegate, BouquetListDelegate,
													ServiceSourceDelegate,
													EditableTableViewCellDelegate,
													EPGRefreshSettingsSourceDelegate>
{
@private
	UIPopoverController *popoverController;
	UIBarButtonItem *_cancelButtonItem;
	UIBarButtonItem *_popoverButtonItem;
	NSDateFormatter *_dateFormatter; /*!< @brief Date formatter. */

	NSInteger pendingRequests; /*!< @brief Pending requests. */
	BOOL _shouldSave; /*!< @brief Should save on exit? */
	BOOL _willReappear; /*!< @brief View will reapper. */
	EPGRefreshSettings *settings; /*!< @brief Plugin settings. */
	NSMutableArray *services; /*!< @brief Restricted services. */
	NSMutableArray *bouquets; /*!< @brief Restricted bouquets. */

	UITextField *_interval; /*!< @brief Time on service. */
	CellTextField *_intervalCell; /*!< @brief Cell of interval field. */
	UITextField *_delay; /*!< @brief Delay if not in standby/in use. */
	CellTextField *_delayCell; /*!< @brief Cell of delay field. */
	UISwitch *_enabled; /*!< @brief Enabled Switch. */
	UISwitch *_force; /*!< @brief Force refresh. */
	UISwitch *_wakeup; /*!< @brief Wakeup for refresh. */
	UISwitch *_shutdown; /*!< @brief Shutdown after refresh. */
	UISwitch *_inherit; /*!< @brief Inherit from AutoTimer. */
	UISwitch *_parse; /*!< @brief Parse AutoTimers after refresh. */

	UIViewController *_bouquetListController; /*!< @brief Cached Bouquet List. */
	UIViewController *_serviceListController; /*!< @brief Cached Service List. */
	UINavigationController *_datePickerNavigationController; /*!< @brief Navigation Controller of Date Picker. */
	DatePickerController *_datePickerController; /*!< @brief Cached Date Picker. */
}

@end
