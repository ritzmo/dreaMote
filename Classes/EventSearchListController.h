//
//  EventSearchListController.h
//  dreaMote
//
//  Created by Moritz Venn on 27.03.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EventListController.h"

/*!
 @brief Event Search.
 */
@interface EventSearchListController : EventListController <UISearchBarDelegate>
{
@private
	UISearchBar	*_searchBar; /*!< @brief Search Bar. */
	UITableView *_tableView; /*!< @brief Table View. */
}

@end
