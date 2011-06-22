//
//  SimpleSingleSelectionListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declaration
@protocol SimpleSingleSelectionListDelegate;

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
	id<SimpleSingleSelectionListDelegate> _delegate; /*!< @brief Delegate. */
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
 @brief Set Delegate.
 
 The delegate will be called back when disappearing to inform it about the newly selected
 item.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<SimpleSingleSelectionListDelegate>) delegate;



/*!
 @brief Selected Item.
 */
@property (nonatomic) NSUInteger selectedItem;

@end



/*!
 @brief SimpleSingleSelectionListController Delegate.
 
 Implements callback functionality for SimpleSingleSelectionListController.
*/
@protocol SimpleSingleSelectionListDelegate<NSObject>

/*!
 @brief Item was selected.
 
 @param newSelection Selected item.
 */
- (void)itemSelected:(NSNumber *)newSelection;

@end
