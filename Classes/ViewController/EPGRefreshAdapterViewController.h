//
//  EPGRefreshAdapterViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 21.05.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declaration
@protocol EPGRefreshAdapterDelegate;

/*!
 @brief Message Type Selector.

 Allows to choose the type of a message to be send to the STB.
 */
@interface EPGRefreshAdapterViewController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>

/*!
 @brief Standard constructor.

 @param adapter Selected adapter.
 @return EPGRefreshAdapterViewController instance.
 */
+ (EPGRefreshAdapterViewController *)withAdapter:(NSString *)adapter;



/*!
 @brief Delegate.
 
 The delegate will be called back when disappearing to inform it about the newly selected
 message type.
 */
@property (nonatomic, unsafe_unretained) id<EPGRefreshAdapterDelegate> delegate;

/*!
 @brief Selected Item.
 */
@property (nonatomic) NSUInteger selectedItem;

@end



/*!
 @brief EPGRefreshAdapterViewController Delegate.

 Implements callback functionality for EPGRefreshAdapterViewController.
*/
@protocol EPGRefreshAdapterDelegate <NSObject>

/*!
 @brief Adapter was selected.

 @param newAdapter Selected adapter.
 */
- (void)adapterSelected:(NSString *)newAdapter;

@end
