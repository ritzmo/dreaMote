//
//  AutoTimerFilterViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.03.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/Generic/AutoTimer.h>

#import "CellTextField.h"

/*!
 @brief Filter was selected.

 @param done NO if cancel was selected.
 @param newFilter Filter text
 @param filterType Type of filter.
 @param include Include Filter?
 @param oldFilter Original text for modified filters
 @param oldInclude Original include/exclude flag for modified filters
 */
typedef void(^autotimerfilter_callback_t)(BOOL, NSString *, autoTimerWhereType, BOOL, NSString*, BOOL);

/*!
 @brief AutoTimer Filter Selector.
 */
@interface AutoTimerFilterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
															EditableTableViewCellDelegate>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	UITextField *filterTextfield; /*!< @brief Filter Label. */
	NSString *currentText; /*!< @brief Current Filter string. */
	autoTimerWhereType filterType; /*!< @brief Current mode. */
	BOOL include; /*!< @brief Include Filter? */
	UIBarButtonItem *_cancelButtonItem; /*!< @brief Cancel button. */

	BOOL oldInclude; /*!< @brief Include state when loaded. */
	NSString *__unsafe_unretained oldText; /*!< @brief Filter string when loaded. */
}

/*!
 @brief Callback.
 */
@property (nonatomic, copy) autotimerfilter_callback_t callback;

/*!
 @brief Filter text.
 */
@property (nonatomic, unsafe_unretained) NSString *currentText;

/*!
 @brief Change Type.
 */
@property (nonatomic, assign) autoTimerWhereType filterType;

/*!
 @brief Include Filter?
 */
@property (nonatomic, assign) BOOL include;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
