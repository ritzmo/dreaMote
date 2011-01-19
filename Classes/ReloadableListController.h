//
//  ReloadableListController.h
//  dreaMote
//
//  Created by Moritz Venn on 06.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EGORefreshTableHeaderView.h"

@class BaseXMLReader;
@class CXMLDocument;

/*!
 @brief Protocol for a subclass of ReloadableListController.
 This protocol is used to make sure that subclasses of ReloadableListController
 properly implement these methods as this might be hidden by the default implementation
 in ReloadableListController otherwise.
 */
@protocol ReloadableView
/*!
 @brief start download of data
 */
- (void)fetchData;

/*!
 @brief Empty content data
 */
- (void)emptyData;
@end

/*!
 @brief Reloadable List Controller
 
 Abstract parent class for reloadable list views.
 */
@interface ReloadableListController : UIViewController <EGORefreshTableHeaderDelegate,
														ReloadableView,
														UIScrollViewDelegate>
{
@protected
	EGORefreshTableHeaderView *_refreshHeaderView; /*!< @brief "Pull up to refresh". */
	BOOL _reloading; /*!< @brief Currently reloading. */
	UITableView *_tableView; /*!< @brief Table view. */
}

/*!
 @brief loadView variant using UITableViewStyleGrouped.
 */
- (void)loadGroupedTableView;

/*!
 @brief Default implementation of xml parser error callback.
 */
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error;

/*!
 @brief Default implementation of xml parser success callback.
 */
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document;

@end