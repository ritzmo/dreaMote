//
//  SimpleRepeatedViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellTextField.h" /* EditableTableViewCellDelegate */

@protocol RepeatedDelegate;

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
	UITextField *_repcountField; /*!< @brief Repeat count. */
	CellTextField *_repcountCell; /*!< @brief Repeat count cell. */
	NSInteger _repeated; /*!< @brief Current Flags. */
	NSInteger _repcount; /*!< @brief Repeat count. */
	id<RepeatedDelegate> _delegate; /*!< @brief Delegate. */
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
 @brief Set Delegate.
 
 The delegate will be called back when disappearing to inform it about the newly selected
 repeated flags.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<RepeatedDelegate>) delegate;



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

@end



/*!
 @brief SimpleRepeatedViewController Delegate.
 
 Implements callback functionality for RepeatedViewController.
 */
@protocol RepeatedDelegate <NSObject>

/*!
 @brief Repeated flags were selected.
 
 @param newRepeated New repeated flags.
 @param newCount New repeated count.
 */
- (void)repeatedSelected:(NSNumber *)newRepeated withCount:(NSNumber *)newCount;

@end
