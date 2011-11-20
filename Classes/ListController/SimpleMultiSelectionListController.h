//
//  SimpleMultiSelectionListController.h
//  dreaMote
//
//  Created by Moritz Venn on 20.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Callback type for selection callbacks.

 @param newSelection Selected item or NSNotFound if invalid.
 @param canceling This is actually a cancel operation.
 */
typedef void (^simplemultiselection_callback_t)(NSSet *newSelection, BOOL canceling);

/*!
 @brief Reusable item selector.
 Allows to choose multiple items from a list of multiple choices.
 */
@interface SimpleMultiSelectionListController : UIViewController <UITableViewDelegate,
																UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
}

/*!
 @brief Standard constructor.

 @param items List of available items
 @param selectedItems Currently selected items
 @param title Title for the view
 @return SimpleMultiSelectionListController instance.
 */
+ (SimpleMultiSelectionListController *)withItems:(NSArray *)items andSelection:(NSSet *)selectedItems andTitle:(NSString *)title;



/*!
 @brief Callback.
 */
@property (nonatomic, copy) simplemultiselection_callback_t callback;

/*!
 @brief Selected Item.
 */
@property (nonatomic, strong) NSMutableSet *selectedItems;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
