//
//  AutoTimerFilterViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/Generic/AutoTimer.h"

#import "CellTextField.h"

@protocol AutoTimerFilterDelegate;

/*!
 @brief AutoTimer Filter Selector.
 */
@interface AutoTimerFilterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
															EditableTableViewCellDelegate>
{
@private
	UITextField *filterTextfield; /*!< @brief Filter Label. */
	NSString *currentText; /*!< @brief Current Filter string. */
	id<AutoTimerFilterDelegate> __unsafe_unretained _delegate; /*!< @brief Delegate. */
	autoTimerWhereType filterType; /*!< @brief Current mode. */
	BOOL include; /*!< @brief Include Filter? */
	UIBarButtonItem *_cancelButtonItem; /*!< @brief Cancel button. */

	BOOL oldInclude; /*!< @brief Include state when loaded. */
	NSString *__unsafe_unretained oldText; /*!< @brief Filter string when loaded. */
}

/*!
 @brief Delegate.

 The delegate will be called back when disappearing to inform it about the filter.
 */
@property (nonatomic, unsafe_unretained) id<AutoTimerFilterDelegate> delegate;

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

@end



/*!
 @brief AutoTimerFilterViewController Delegate.
 
 Implements callback functionality for AutoTimerFilterViewController.
 */
@protocol AutoTimerFilterDelegate <NSObject>

/*!
 @brief Filter was selected.
 
 @param newFilter Filter text
 @param filterType Type of filter.
 @param include Include Filter?
 @param oldFilter Original text for modified filters
 @param oldInclude Original include/exclude flag for modified filters
 */
- (void)filterSelected:(NSString *)newFilter filterType:(autoTimerWhereType)filterType include:(BOOL)include oldFilter:(NSString *)oldFilter oldInclude:(BOOL)oldInclude;

@end
