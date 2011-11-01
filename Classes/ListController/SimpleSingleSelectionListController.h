//
//  SimpleSingleSelectionListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Callback type for selection callbacks.
 Called upon selection of an item with the selected item and NO as parameters,
 or the selected item and YES when dismissing.
 The block should return YES if the selection is actually final.
 @note A final selection will result in the callback being removed and the
 parent view is assumed to remove this view.
 */
typedef BOOL (^simplesingleselection_callback_t)(NSUInteger, BOOL);

/*!
 @brief Reusable single item selector.
 
 Allows to choose a single item from a list of multiple choices.
 */
@interface SimpleSingleSelectionListController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	NSArray *_items; /*!< @brief Items. */
	NSUInteger _selectedItem; /*!< @brief Selected Item. */
	simplesingleselection_callback_t callback; /*!< @brief Delegate. */
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

@end
