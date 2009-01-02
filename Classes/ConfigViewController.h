//
//  ConfigViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h"

@interface ConfigViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, EditableTableViewCellDelegate>
{
@private
	UITextField *remoteAddressTextField;
	CellTextField *remoteAddressCell;
	UITextField *usernameTextField;
	CellTextField *usernameCell;
	UITextField *passwordTextField;
	CellTextField *passwordCell;
	UITableViewCell *connectorCell;
	NSMutableDictionary *connection;
	NSInteger connectionIndex;
	UIButton *makeDefaultButton;
	UIButton *connectButton;
	UISwitch *_singleBouquetSwitch;

	BOOL _shouldSave;
	NSInteger _connector;
}

+ (ConfigViewController *)withConnection: (NSMutableDictionary *)newConnection: (NSInteger)atIndex;
+ (ConfigViewController *)newConnection;

@property (nonatomic,retain) NSMutableDictionary *connection;
@property (nonatomic,retain) UIButton *makeDefaultButton;
@property (nonatomic,retain) UIButton *connectButton;
@property (nonatomic) NSInteger connectionIndex;

@end
