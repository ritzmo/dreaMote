//
//  AutoTimerFilterViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
	AutoTimerFilterTypeText,
	AutoTimerFilterTypeWeekday,
} AutoTimerFilterType;

@protocol AutoTimerFilterDelegate;

/*!
 @brief AutoTimer Filter Selector.
 */
@interface AutoTimerFilterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	UITextField *filterTextfield; /*!< @brief Filter Label. */
	NSString *currentText; /*!< @brief Current Filter string. */
	id<AutoTimerFilterDelegate> _delegate; /*!< @brief Delegate. */
	AutoTimerFilterType filterType; /*!< @brief Current mode. */
	BOOL include; /*!< @brief Include Filter? */
}

/*!
 @brief Set Delegate.
 
 The delegate will be called back when disappearing to inform it about the filter.
 
 @param delegate New delegate object.
 */
- (void)setDelegate:(id<AutoTimerFilterDelegate>)delegate;

/*!
 @brief Filter text.
 */
@property (nonatomic, retain) NSString *currentText;

/*!
 @brief Change Type.
 */
@property (nonatomic, assign) AutoTimerFilterType filterType;

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
 @param include Include Filter?
 */
- (void)filterSelected:(NSString *)newFilter include:(BOOL)include;

@end
