//
//  SearchHistoryListController.h
//  dreaMote
//
//  Created by Moritz Venn on 13.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchHistoryListDelegate;

@interface SearchHistoryListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_history; /*!< @brief Previously looked for strings. */
	NSObject<SearchHistoryListDelegate> *__unsafe_unretained _historyDelegate; /*!< @brief Delegate. */
	UITableView *_tableView; /*!< @brief Table View. */
}

/*!
 @brief Add string to top of list.
 @note If the history already contains string it is moved to the top of the list

 @param new String to add.
 */
- (void)prepend:(NSString *)new;

/*!
 @brief Save history.
 */
- (void)saveHistory;

@property (nonatomic, unsafe_unretained) NSObject<SearchHistoryListDelegate> *historyDelegate;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end

@protocol SearchHistoryListDelegate

/*!
 @brief Invoke a search

 @param text Text to search for.
 */
- (void)startSearch:(NSString *)text;

@end
