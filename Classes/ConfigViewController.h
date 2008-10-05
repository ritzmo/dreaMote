//
//  ConfigViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h"
#import "DisplayCell.h"

@interface ConfigViewController : UIViewController <UIScrollViewDelegate,
													UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, EditableTableViewCellDelegate>
{
	UITableView *myTableView;
	UITextField *remoteAddressTextField;
	CellTextField *remoteAddressCell;
	UITextField *usernameTextField;
	CellTextField *usernameCell;
	UITextField *passwordTextField;
	CellTextField *passwordCell;
	UITableViewCell *connectorCell;
	UISwitch *vibrateInRC;
	NSMutableDictionary *connection;
	@private
	BOOL _shouldSave;
	BOOL _isNew;
	NSInteger _connector;
}

@end

