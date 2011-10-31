//
//  ServiceListController.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"
#import "NowNextSourceDelegate.h"
#import "ServiceSourceDelegate.h"
#import "BouquetListController.h" /* BouquetListDelegate */
#import "EventViewController.h"
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */
#import "ServiceZapListController.h" /* ServiceZapListDelegate */
#if IS_FULL()
	#import "MultiEPGListController.h" /* MultiEPGDelegate */
#endif
#import "SimpleSingleSelectionListController.h" /* SimpleSingleSelectionListDelegate */

// Forward declarations
@class BaseXMLReader;
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
													ServiceZapListDelegate,
#if IS_FULL()
													MultiEPGDelegate,
#endif
													SimpleSingleSelectionListDelegate,
													UIActionSheetDelegate,
													UIAlertViewDelegate,
													ServiceListDelegate,
													BouquetListDelegate,
													MGSplitViewControllerDelegate>
{
@private
	NSInteger pendingRequests; /*!< @brief Number of currently pending requests. */
	UIPopoverController *popoverController; /*!< @brief Popover Controller. */
	UIPopoverController *popoverZapController; /*!< @brief Popover Zap Controller. */
	NSObject<ServiceProtocol> *_bouquet; /*!< @brief Current Bouquet. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Selected Service (if executing a gesture, borrowed reference). */
	NSMutableArray *_mainList; /*!< @brief Service/Current Event List. */
	NSMutableArray *_subList; /*!< @brief Next Event List. */
	id<ServiceListDelegate, NSCoding, UIAppearanceContainer> _delegate; /*!< @brief Delegate. */
	BOOL _refreshServices; /*!< @brief Refresh Service List on next open? */
	BOOL _isRadio; /*!< @brief Are we in radio mode? */
	EventListController *_eventListController; /*!< @brief Caches Event List View. */
	UIBarButtonItem *_radioButton; /*!< @brief Radio/TV-mode toggle */
	UIBarButtonItem *_multiEpgButton; /*!< @brief Multi-EPG toggle */
	BOOL _supportsNowNext; /*!< @brief Use now/next mode to retrieve Events */
	NSDateFormatter *_dateFormatter; /*!< @brief Date formatter used for now/next */
	EventViewController *_eventViewController; /*!< @brief Event View Controller. */
	MGSplitViewController *_mgSplitViewController; /*!< @brief Associated MGSplitViewController. */
	ServiceZapListController *_zapListController; /*!< @brief Zap List controller. */
#if IS_FULL()
	MultiEPGListController *_multiEPG; /*!< @brief Multi EPG. */
#endif

	BaseXMLReader *_xmlReader; /*!< Current Service/Event XML Document. */
	BaseXMLReader *_xmlReaderSub; /*!< Next Event XML Document. */
}

/*!
 @brief Set Service Selection Delegate.
 
 This Function is required for Timers as they will use the provided Callback when you change the
 Service of a Timer.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<ServiceListDelegate, NSCoding>) delegate;

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
 @brief Shows now next?
 Can be used to force-disable now/next e.g. when showing 'All Services' bouquet.

 @note Might be of use in delegate mode also...
 */
@property (nonatomic, assign) BOOL showNowNext;

/*!
 @brief Bouquet.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *bouquet;

/*!
 @brief Currently in radio mode?
 */
@property (nonatomic) BOOL isRadio;

/*!
 @brief Associated MGSplitViewController.
 */
@property (nonatomic, assign) MGSplitViewController *mgSplitViewController;

/*!
 @brief Currently reloading.
 */
@property (nonatomic, readonly) BOOL reloading;

@end
