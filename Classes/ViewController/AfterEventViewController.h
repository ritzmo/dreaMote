//
//  AfterEventViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AfterEventDelegate;

/*!
 @brief After Event Selector.
 
 Allows to select an after event action from the list defined by enum afterEvent.
 */
@interface AfterEventViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	NSInteger _selectedItem; /*!< @brief Selected Item. */
	BOOL _showAuto; /*!< @brief Show "kAfterEventAuto" Item? */
	BOOL _showDefault; /*!< @brief Show "Default Action" for kAfterEventMax? */
}

/*!
 @brief Standard Constructor.
 
 Open new instance of this ViewController with given settings.
 
 @param afterEvent Selected After Event Action.
 @param showAuto Show "kAfterEventAuto" Item?
 @return AfterEventViewController instance.
 */
+ (AfterEventViewController *)withAfterEvent: (NSUInteger)afterEvent andAuto: (BOOL)showAuto;



/*!
 @brief Set Delegate.

 The delegate will be called back when disappearing to inform it about the newly selected
 after event action.
 */
@property (nonatomic, unsafe_unretained) id<AfterEventDelegate> delegate;

/*!
 @brief Selected Item.
 */
@property (assign) NSUInteger selectedItem;

/*!
 @brief Show "kAfterEventAuto" Item?
 */
@property (assign) BOOL showAuto;

/*!
 @brief Show "Default Action" for kAfterEventMax?
 */
@property (assign) BOOL showDefault;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end



/*!
 @brief AfterEventViewController Delegate.
 
 Implements callback functionality for AfterEventViewController.
 */
@protocol AfterEventDelegate <NSObject>

/*!
 @brief After event was selected.
 
 @param newAfterEvent Selected action..
 */
- (void)afterEventSelected: (NSNumber *)newAfterEvent;

@end
