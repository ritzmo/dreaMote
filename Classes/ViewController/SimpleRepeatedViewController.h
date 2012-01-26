//
//  SimpleRepeatedViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.06.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h" /* EditableTableViewCellDelegate */

/*!
 @brief Callback type for "repeated" callbacks.

 @param repeated The flags for "repeated".
 @param repeatcount If supported, the number of repetitions, else undefined.
 */
typedef void (^simplerepeated_callback_t)(NSInteger repeated, NSInteger repcount);

/*!
 @brief Repeated Flag selection.
 
 Allows to select repeated flags from a simple set of available values.
 It's adjusted to the Enigma and Enigma2 model of repeating timers thus it only
 offers weakly repetitions based on days.
 */
@interface SimpleRepeatedViewController : UIViewController <EditableTableViewCellDelegate,
															UITableViewDelegate, UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	UITextField *_repcountField; /*!< @brief Repeat count. */
	CellTextField *_repcountCell; /*!< @brief Repeat count cell. */
	NSInteger _repeated; /*!< @brief Current Flags. */
	NSInteger _repcount; /*!< @brief Repeat count. */
	BOOL _isSimple; /*!< @brief Simple Editor? */
}

/*!
 @brief Standard constructor.
 
 @param repeated Flags to start with.
 @param repcount Repeatecount
 @return SimpleRepeatedViewController instance.
 */
+ (SimpleRepeatedViewController *)withRepeated: (NSInteger)repeated andCount: (NSInteger)repcount;



/*!
 @brief Callback.
 */
@property (nonatomic, copy) simplerepeated_callback_t callback;

/*!
 @brief Repeated Flags.
 */
@property (assign) NSInteger repeated;

/*!
 @brief Number of repititions (in non-simple mode)
 */
@property (assign) NSInteger repcount;

/*!
 @brief "Simple" Editor?
 */
@property (assign) BOOL isSimple;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
