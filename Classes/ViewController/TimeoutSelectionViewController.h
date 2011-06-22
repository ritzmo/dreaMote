//
//  TimeoutSelectionViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 14.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
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
	NSUInteger _selectedItem; /*!< @brief Selected Item. */
	NSObject<TimeoutSelectionDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard constructor.
 
 @param timeout Current timeout.
 @return TimeoutSelectionViewController instance.
 */
+ (TimeoutSelectionViewController *)withTimeout:(NSInteger)timeout;

/*!
 @brief Set Delegate.

 The delegate will be called back when disappearing to inform it that the timeout
 was changed.

 @param delegate New delegate object.
 */
- (void)setDelegate:(NSObject<TimeoutSelectionDelegate> *)delegate;



/*!
 @brief Selected Item.
 */
@property (nonatomic) NSUInteger selectedItem;

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
