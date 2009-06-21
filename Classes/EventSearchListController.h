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
	UISearchBar	*searchBar; /*!< @brief Search Bar. */
	UITableView *tableView; /*!< @brief Table View. */
}

@end
