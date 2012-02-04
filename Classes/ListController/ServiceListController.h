//
//  ServiceListController.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"
#import "NowNextSourceDelegate.h"
#import "ServiceSourceDelegate.h"
#import "BouquetListController.h" /* BouquetListDelegate */
#import "EventViewController.h"
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */
#if IS_FULL()
	#import "MultiEPGListController.h" /* MultiEPGDelegate */
#endif

// Forward declarations
@class SaxXmlReader;
@class EventListController;
@protocol ServiceProtocol;


/*!
 @brief Delegate for ServiceListController.

 Objects wanting to be called back by a ServiceListController need to implement this Protocol.
 */
@protocol ServiceListDelegate <NSObject>

/*!
 @brief Service was selected.

 @param newService Service that was selected.
 */
- (void)serviceSelected: (NSObject<ServiceProtocol> *)newService;

/*!
 @brief Remove alternatives for current service.

 @param service Service to remove alternatives for.
 */
@optional
- (void)removeAlternatives:(NSObject<ServiceProtocol> *)service;

@end



/*!
 @brief Service List.
 
 Lists services of a Bouquet and opens EventListController for this Service upon
 selection.
 */
@interface ServiceListController : ReloadableListController <UITableViewDelegate,
													UITableViewDataSource,
													UIPopoverControllerDelegate,
													ServiceSourceDelegate,
													NowSourceDelegate,
													NextSourceDelegate,
													SwipeTableViewDelegate,
#if IS_FULL()
													MultiEPGDelegate,
#endif
													UIActionSheetDelegate,
													UIAlertViewDelegate,
													ServiceListDelegate,
													BouquetListDelegate,
													UISearchDisplayDelegate,
													MGSplitViewControllerDelegate>
{
@private
	NSInteger pendingRequests; /*!< @brief Number of currently pending requests. */
	UIPopoverController *popoverController; /*!< @brief Popover Controller. */
	UIPopoverController *popoverZapController; /*!< @brief Popover Zap Controller. */
	NSObject<ServiceProtocol> *_bouquet; /*!< @brief Current Bouquet. */
	NSMutableArray *_mainList; /*!< @brief Service/Current Event List. */
	NSMutableArray *_subList; /*!< @brief Next Event List. */
	BOOL _refreshServices; /*!< @brief Refresh Service List on next open? */
	BOOL _isRadio; /*!< @brief Are we in radio mode? */
	EventListController *_eventListController; /*!< @brief Caches Event List View. */
	UIBarButtonItem *_radioButton; /*!< @brief Radio/TV-mode toggle */
	UIBarButtonItem *_multiEpgButton; /*!< @brief Multi-EPG toggle */
	BOOL _supportsNowNext; /*!< @brief Use now/next mode to retrieve Events */
	NSDateFormatter *_dateFormatter; /*!< @brief Date formatter used for now/next */
	EventViewController *_eventViewController; /*!< @brief Event View Controller. */
#if IS_FULL()
	MultiEPGListController *_multiEPG; /*!< @brief Multi EPG. */
#endif

	NSOperationQueue *_piconLoader; /*!< @brief Background operations loading the picons. */

	NSMutableArray *_selectedServices; /*!< @brief Currently selected services. */
	NSMutableArray *_filteredServices; /*!< @brief Filtered list of services when searching. */
	UISearchBar *searchBar; /*!< @brief Search bar. */
	UISearchDisplayController *_searchDisplay; /*!< @brief Search display. */

	SaxXmlReader *_xmlReaderSub; /*!< XMLReader for list of 'Next' events if showing now/next. */
}

/*!
 @brief Move service selection to next item and return movie.
 @note If current service is last in list, don't move selection and return nil.

 @return Newly selected service.
 */
- (NSObject<ServiceProtocol> *)nextService;

/*!
 @brief Move service selection to previous item and return movie.
 @note If current service is first in list, don't move selection and return nil.

 @return Newly selected service.
 */
- (NSObject<ServiceProtocol> *)previousService;


/*!
 @brief Force isRadio variable to a certain value.
 Optimizes things a bit on the iPhone.
 */
- (void)forceRadio:(BOOL)newIsRadio;


/*!
 @brief Search bar.
 */
@property (nonatomic, readonly) UISearchBar *searchBar;

/*!
 @brief Shows now next?
 Can be used to force-disable now/next e.g. when showing 'All Services' bouquet.

 @note Might be of use in delegate mode also...
 */
@property (nonatomic, assign) BOOL showNowNext;

/*!
 @brief Are we showing 'All Services'?
 This is used to disable some animations because they take ages in large 'bouquets'.
 */
@property (nonatomic, assign) BOOL isAll;

/*!
 @brief Bouquet.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> *bouquet;

/*!
 @brief Service Selection Delegate.

 This Function is required for Timers as they will use the provided Callback when you change the
 Service of a Timer.
 */
@property (nonatomic, unsafe_unretained) NSObject<ServiceListDelegate, UIAppearanceContainer> *delegate;

/*!
 @brief Currently in radio mode?
 */
@property (nonatomic) BOOL isRadio;

/*!
 @brief Is this view slave to a split view?
 */
@property (nonatomic, readonly) BOOL isSlave;

/*!
 @brief Associated MGSplitViewController.
 */
@property (nonatomic, unsafe_unretained) MGSplitViewController *mgSplitViewController;

/*!
 @brief Currently reloading.
 */
@property (nonatomic, readonly) BOOL reloading;

@end
