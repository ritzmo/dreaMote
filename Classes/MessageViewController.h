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
	UITextField *_messageTextField; /*!< @brief Text Field. */
	CellTextField *_messageCell; /*!< @brief Text Cell. */
	UITextField *_captionTextField; /*!< @brief Caption Field. */
	CellTextField *_captionCell; /*!< @brief Caption Cell. */
	UITextField *_timeoutTextField; /*!< @brief Timeout Field. */
	CellTextField *_timeoutCell; /*!< @brief Timeout Cell. */
	UIButton *_sendButton; /*!< @brief "Send" Button. */
	NSInteger _type; /*!< @brief Selected message type. */
	UITableViewCell *_typeCell; /*!< @brief Cell with textual representation of message type. */
}

@end
