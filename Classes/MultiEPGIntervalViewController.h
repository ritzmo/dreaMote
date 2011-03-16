//
//  MultiEPGIntervalViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 16.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MultiEPGIntervalDelegate;

/*!
 @brief Multi EPG Interval Selector.
 
 Allows the user to chose the time interval displayed in Multi EPG.
 */
@interface MultiEPGIntervalViewController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	NSUInteger _selectedItem; /*!< @brief Selected Item. */
	NSObject<MultiEPGIntervalDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard constructor.
 
 @param interval Current interval.
 @return MultiEPGIntervalViewController instance.
 */
+ (MultiEPGIntervalViewController *)withInterval: (NSUInteger)interval;

/*!
 @brief Set Delegate.

 The delegate will be called back when disappearing to inform it that the interval
 was changed.

 @param delegate New delegate object.
 */
- (void)setDelegate:(NSObject<MultiEPGIntervalDelegate> *)delegate;



/*!
 @brief Selected Item.
 */
@property (nonatomic) NSUInteger selectedItem;

@end



/*!
 @brief MultiEPGIntervalViewController Delegate.
 */
@protocol MultiEPGIntervalDelegate
/*!
 @brief Interval was changed.
 */
- (void)didSetInterval;
@end