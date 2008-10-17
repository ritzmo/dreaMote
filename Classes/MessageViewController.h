//
//  MessageViewController.h
//  Untitled
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h"

@interface MessageViewController : UIViewController <UIScrollViewDelegate,
													UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, EditableTableViewCellDelegate>
{
@private
	UITextField *messageTextField;
	CellTextField *messageCell;
	UITextField *captionTextField;
	CellTextField *captionCell;
	UITextField *timeoutTextField;
	CellTextField *timeoutCell;
	UIButton *sendButton;
	NSInteger _type;
	UITableViewCell *typeCell;
}

@end
