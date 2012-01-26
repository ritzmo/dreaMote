//
//  SimpleSingleSelectionListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Callback type for selection callbacks.

 @param newSelection Selected item or NSNotFound if invalid.
 @param willDisappear View is closing.
 @param canceling This is actually a cancel operation.
 @return YES if this selection is final and the view will disappear.
 */
typedef BOOL (^simplesingleselection_callback_t)(NSUInteger newSelection, BOOL willDisappear, BOOL canceling);

/*!
 @brief Reusable single item selector.
 @todo Add convenience method to show UIActionSheet (on iPhone/iPod Touch)
 Allows to choose a single item from a list of multiple choices.
 */
@interface SimpleSingleSelectionListController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	NSArray *_items; /*!< @brief Items. */
	UITableView *_tableView; /*!< @brief Table View. */
}

/*!
 @brief Standard constructor.
 
 @param items List of available items
 @param selectedItem Currently selected item
 @param title Title for the view
 @return SimpleSingleSelectionListController instance.
 */
+ (SimpleSingleSelectionListController *)withItems:(NSArray *)items andSelection:(NSUInteger)selectedItem andTitle:(NSString *)title;



/*!
 @brief Callback.
 */
@property (nonatomic, copy) simplesingleselection_callback_t callback;

/*!
 @brief Selected Item.
 */
@property (nonatomic) NSUInteger selectedItem;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
