//
//  SearchHistoryLengthEditorController.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchHistoryLengthEditorDelegate;

/*!
 @brief Timeout Selector.

 Allows the user to choose the connection timeout.
 */
@interface SearchHistoryLengthEditorController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	UITextField *_lengthTextField; /*!< @brief Text Field. */
	NSInteger _length; /*!< @brief Current length as integer. */
}

/*!
 @brief Standard constructor.
 
 @param length Current timeout.
 @return SearchHistoryLengthEditorController instance.
 */
+ (SearchHistoryLengthEditorController *)withLength:(NSInteger)length;

/*!
 @brief Delegate.

 The delegate will be called back when disappearing to inform it that the length
 was changed.
 */
@property (nonatomic, unsafe_unretained) NSObject<SearchHistoryLengthEditorDelegate> *delegate;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end



/*!
 @brief SearchHistoryLengthEditorController Delegate.
 */
@protocol SearchHistoryLengthEditorDelegate
/*!
 @brief Timeout was changed.
 */
- (void)didSetLength;
@end
