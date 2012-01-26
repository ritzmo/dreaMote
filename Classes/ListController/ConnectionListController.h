//
//  ConnectionListController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.06.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ConnectionListDelegate;

/*!
 @brief Connection List used in AutoConfiguration.
 
 Displays a given list of possible connections.
 */
@interface ConnectionListController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	NSArray *_connections; /*!< @brief List of found connections. */
	NSObject<ConnectionListDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard constructor.

 @param connections
 @param configView
 @return ConnectionListController instance.
 */
+ (ConnectionListController *)newWithConnections:(NSArray *)connections andDelegate:(NSObject<ConnectionListDelegate> *)delegate;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end

/*!
 @brief Callbacks of ConnectionListController.
 */
@protocol ConnectionListDelegate
/*!
 @brief A connection was selected.

 @param dictionary Connection dictionary.
 */
- (void)connectionSelected:(NSMutableDictionary *)dictionary;
@end