//
//  ReloadableListController.h
//  dreaMote
//
//  Created by Moritz Venn on 06.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EGORefreshTableHeaderView.h"
#import "SwipeTableView.h"

@class BaseXMLReader;
@class MGSplitViewController;

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
	SwipeTableView *_tableView; /*!< @brief Table view. */
	BaseXMLReader *_xmlReader; /*!< @brief Current XML Document. */
}

/*!
 @brief loadView variant using UITableViewStyleGrouped.
 */
- (void)loadGroupedTableView;

/*!
 @brief Default implementation of xml parser error callback.
 */
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error;

/*!
 @brief Default implementation of xml parser success callback.
 */
- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource;

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc;
- (void)splitViewController:(MGSplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem;

@property (nonatomic, readonly) SwipeTableView *tableView;

@end