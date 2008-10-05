//
//  ConfigViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h"

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
	NSMutableDictionary *connection;
	NSInteger connectionIndex;
	UIButton *makeDefaultButton;
	@private
	BOOL _shouldSave;
	NSInteger _connector;
}

+ (ConfigViewController *)withConnection: (NSMutableDictionary *)newConnection: (NSInteger)atIndex;
+ (ConfigViewController *)newConnection;

@property (nonatomic,retain) NSMutableDictionary *connection;
@property (nonatomic) NSInteger connectionIndex;

@end
