//
//  MessageViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h"

/*!
 @brief Message View.
 */
@interface MessageViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, EditableTableViewCellDelegate>
{
@private
	UITextField *messageTextField; /*!< @brief Text Field. */
	CellTextField *messageCell; /*!< @brief Text Cell. */
	UITextField *captionTextField; /*!< @brief Caption Field. */
	CellTextField *captionCell; /*!< @brief Caption Cell. */
	UITextField *timeoutTextField; /*!< @brief Timeout Field. */
	CellTextField *timeoutCell; /*!< @brief Timeout Cell. */
	UIButton *sendButton; /*!< @brief "Send" Button. */
	NSInteger _type; /*!< @brief Selected message type. */
	UITableViewCell *typeCell; /*!< @brief Cell with textual representation of message type. */
}

@end
