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
	UITextField *_lengthTextField; /*!< @brief Text Field. */
	NSObject<SearchHistoryLengthEditorDelegate> __unsafe_unretained *_delegate; /*!< @brief Delegate. */
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
