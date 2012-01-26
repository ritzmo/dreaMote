//
//  MessageViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h" /* CellTextField, EditableTableViewCellDelegate */

/*!
 @brief Message View.
 
 View to be used to send messages to the STB.
 */
@interface MessageViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource,
													EditableTableViewCellDelegate>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	UITextField *_messageTextField; /*!< @brief Text Field. */
	CellTextField *_messageCell; /*!< @brief Text Cell. */
	UITextField *_captionTextField; /*!< @brief Caption Field. */
	CellTextField *_captionCell; /*!< @brief Caption Cell. */
	UITextField *_timeoutTextField; /*!< @brief Timeout Field. */
	CellTextField *_timeoutCell; /*!< @brief Timeout Cell. */
	UIButton *_sendButton; /*!< @brief "Send" Button. */
	NSUInteger _type; /*!< @brief Selected message type. */
	UITableViewCell __unsafe_unretained *_typeCell; /*!< @brief Cell with textual representation of message type. */
}


/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
