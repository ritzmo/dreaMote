//
//  PackageManagerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"
#import "ReloadableListController.h"

/*!
 @brief Package ManagerList.
 */
@interface PackageManagerListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															UISearchDisplayDelegate>
{
@private
	NSArray *_packages; /*!< @brief Package List. */
	BOOL _refreshPackages; /*!< @brief Refresh on next viewWillAppear? */
	enum packageManagementList _listType; /*!< @brief Currently shown list. */
	NSMutableArray *_selectedPackages; /*!< @brief Selected packages. */

	NSMutableArray *_filteredPackages; /*!< @brief Filtered list of packages when searching. */
	UISearchBar *_searchBar; /*!< @brief Search bar. */
	UISearchDisplayController *_searchDisplay; /*!< @brief Search display. */
}

/*!
 @brief View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end