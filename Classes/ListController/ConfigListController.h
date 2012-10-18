//
//  ConfigListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ConnectionListController.h" /* ConnectionListDelegate */
#import "SearchHistoryLengthEditorController.h" /* SearchHistoryLengthEditorDelegate */
#import "TimeoutSelectionViewController.h" /* TimeoutSelectionDelegate */
#import "MBProgressHUD.h" /* MBProgressHUDDelegate */

/*!
 @brief General settings and connection list.
 
 Allows to set Application preferences and Add/Remove of known Connections.
 */
@interface ConfigListController : UIViewController <UITableViewDelegate,
													ConnectionListDelegate,
													TimeoutSelectionDelegate,
													UITableViewDataSource,
													SearchHistoryLengthEditorDelegate,
													MBProgressHUDDelegate>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	NSMutableArray *_connections; /*!< @brief List of Connections. */
	UISwitch *_vibrateInRC; /*!< @brief "Vibrate in RC" UISwitch. */
	UISwitch *_simpleRemote; /*!< @brief "Use simple remote" UISwitch. */
	UISwitch *_sepEventsByDay; /*!< @brief "Separate events by day" UISwitch. */
    UITextField *_customActionTextField; /*!< @brief Name Text Field. */
	MBProgressHUD *progressHUD; /*!< @brief ProgressHUD if being shown. */
	NSArray *purchasables; /*!< @brief List of purchasable objects. */
}

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
