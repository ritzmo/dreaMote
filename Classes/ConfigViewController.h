//
//  ConfigViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h"

/*!
 @brief Connection Settings.
 */
@interface ConfigViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, EditableTableViewCellDelegate>
{
@private
	UITextField *remoteNameTextField; /*!< @brief Name Text Field. */
	CellTextField *remoteNameCell; /*!< @brief Name Cell. */
	UITextField *remoteAddressTextField; /*!< @brief  Text Field. */
	CellTextField *remoteAddressCell; /*!< @brief Address Cell. */
	UITextField *remotePortTextField; /*!< @brief Port Text Field. */
	CellTextField *remotePortCell; /*!< @brief Port Cell. */
	UITextField *usernameTextField; /*!< @brief Username Text Field. */
	CellTextField *usernameCell; /*!< @brief Username Cell. */
	UITextField *passwordTextField; /*!< @brief Password Text Field. */
	CellTextField *passwordCell; /*!< @brief Password Cell. */
	UITableViewCell *connectorCell; /*!< @brief Connector Cell. */
	NSMutableDictionary *connection; /*!< @brief Connection Dictionary. */
	NSInteger connectionIndex; /*!< @brief Index in List of known Connections. */
	UIButton *makeDefaultButton; /*!< @brief "Make Default" Button. */
	UIButton *connectButton; /*!< @brief "Connect" Button. */
	UISwitch *_singleBouquetSwitch; /*!< @brief Switch for "Single Bouquet Mode" if Connector supports it. */

	BOOL _shouldSave; /*!< @brief Settings should be Saved. */
	NSInteger _connector; /*!< @brief Selected Connector. */
}

/*!
 @brief Standard Constructor.
 
 Edit known Connection.
 
 @param newConnection Connection Dictionary.
 @param atIndex Index in List of known Connections.
 @return ConfigViewController instance.
 */
+ (ConfigViewController *)withConnection: (NSMutableDictionary *)newConnection: (NSInteger)atIndex;

/*!
 @brief Standard Constructor.

 Create new Connection.
 
 @return ConfigViewController instance.
 */
+ (ConfigViewController *)newConnection;



/*!
 @brief Connection Dictionary.
 */
@property (nonatomic,retain) NSMutableDictionary *connection;

/*!
 @brief "Make Default" Button.
 */
@property (nonatomic,retain) UIButton *makeDefaultButton;

/*!
 @brief "Connect" Button.
 */
@property (nonatomic,retain) UIButton *connectButton;

/*!
 @brief Index in List of known Connections.
 */
@property (nonatomic) NSInteger connectionIndex;

@end
