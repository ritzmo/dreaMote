//
//  TimeoutSelectionViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 14.04.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TimeoutSelectionDelegate;

/*!
 @brief Timeout Selector.

 Allows the user to choose the connection timeout.
 */
@interface TimeoutSelectionViewController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
}

/*!
 @brief Standard constructor.
 
 @param timeout Current timeout.
 @return TimeoutSelectionViewController instance.
 */
+ (TimeoutSelectionViewController *)withTimeout:(NSInteger)timeout;



/*!
 @brief Delegate.

 The delegate will be called back when disappearing to inform it that the timeout
 was changed.
 */
@property (nonatomic, unsafe_unretained) NSObject<TimeoutSelectionDelegate> *delegate;

/*!
 @brief Selected Item.
 */
@property (nonatomic) NSUInteger selectedItem;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end



/*!
 @brief TimeoutSelectionViewController Delegate.
 */
@protocol TimeoutSelectionDelegate
/*!
 @brief Timeout was changed.
 */
- (void)didSetTimeout;
@end
