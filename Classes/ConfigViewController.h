//
//  ConfigViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h" /* EditableTableViewCellDelegate */
#import "ConnectorViewController.h" /* ConnectorDelegate */

/*!
 @brief Connection Settings.
 
 Allows to change settings of a known or new connection, make it default or just connect and
 finally save / dismiss changes.
 */
@interface ConfigViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, ConnectorDelegate,
													EditableTableViewCellDelegate>
{
@private
	UITextField *_remoteNameTextField; /*!< @brief Name Text Field. */
	CellTextField *_remoteNameCell; /*!< @brief Name Cell. */
	UITextField *_remoteAddressTextField; /*!< @brief  Text Field. */
	CellTextField *_remoteAddressCell; /*!< @brief Address Cell. */
	UITextField *_remotePortTextField; /*!< @brief Port Text Field. */
	CellTextField *_remotePortCell; /*!< @brief Port Cell. */
	UITextField *_usernameTextField; /*!< @brief Username Text Field. */
	CellTextField *_usernameCell; /*!< @brief Username Cell. */
	UITextField *_passwordTextField; /*!< @brief Password Text Field. */
	CellTextField *_passwordCell; /*!< @brief Password Cell. */
	UITableViewCell *_connectorCell; /*!< @brief Connector Cell. */
	NSMutableDictionary *_connection; /*!< @brief Connection Dictionary. */
	NSInteger _connectionIndex; /*!< @brief Index in List of known Connections. */
	UIButton *_makeDefaultButton; /*!< @brief "Make Default" Button. */
	UIButton *_connectButton; /*!< @brief "Connect" Button. */
	UISwitch *_singleBouquetSwitch; /*!< @brief Switch for "Single Bouquet Mode" if Connector supports it. */
	/*!
	 @brief Switch for "Advanced Remote" if Connector supports it.
	 
	 @todo This might be of use in other connectors too, recheck!
	 */
	UISwitch *_advancedRemoteSwitch;
	UISwitch *_sslSwitch; /*!< @brief Switch to enable SSL. */

	BOOL _mustSave;
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
 @brief Standard Constructor.
 
 Create first Connection.
 
 @return ConfigViewController instance.
 */
+ (ConfigViewController *)firstConnection;



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

/*!
 @brief Force user to save this entry.
 */
@property (nonatomic) BOOL mustSave;

@end
