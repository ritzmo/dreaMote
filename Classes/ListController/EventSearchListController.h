//
//  EventSearchListController.h
//  dreaMote
//
//  Created by Moritz Venn on 27.03.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "EventListController.h"

#import "SearchHistoryListController.h"

/*!
 @brief Event Search.
 
 Allow to search for events, lists the results and opens an EventViewController upon
 selection.
 */
@interface EventSearchListController : EventListController <UISearchBarDelegate,
														UIPopoverControllerDelegate,
														SearchHistoryListDelegate>
{
@private
	SearchHistoryListController *_searchHistory; /*!< @brief Search History */
}

@property (unsafe_unretained, nonatomic, readonly) SearchHistoryListController *searchHistory;

@end
